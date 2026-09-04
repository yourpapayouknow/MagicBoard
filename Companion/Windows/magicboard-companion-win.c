/**
 * MagicBoard Windows 原生伴侣服务 (单文件绿色版免安装 C 原生程序)
 * 
 * 编译说明 (MinGW-W64 GCC):
 *   gcc -O2 -Wall -o magicboard-companion-win.exe magicboard-companion-win.c -lws2_32 -luser32 -lshell32
 * 
 * 功能特性:
 *   1. 监听来自 iPad 的 MBCP v1 16 字节二进制 UDP 报文 (默认端口 52088)
 *   2. 精确映射 USB HID Usage (Page 0x07) 到 Windows Virtual-Key 与硬件扫描码
 *   3. 采用官方 SendInput API 注入按键事件
 *   4. 支持管理员权限检测与 --elevate 自动 UAC 提权突破 UIPI 隔离
 *   5. 实现 Pulse 单包脉冲按键与 1.5 秒断网看门狗防卡键机制
 *   6. 支持一键放行 Windows 防火墙入站规则指引及 --add-firewall 指令
 */

#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0601

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

// ==============================================================================
// 1. 协议常量定义 (MBCP v1)
// ==============================================================================
#define PROTOCOL_MAGIC       0x4D424350  // ASCII "MBCP"
#define PROTOCOL_VERSION     1
#define PACKET_LENGTH        16
#define DEFAULT_PORT         52088

#define ACTION_KEY_DOWN      0x01
#define ACTION_KEY_UP        0x02
#define ACTION_PULSE         0x03
#define ACTION_HEARTBEAT     0x04
#define ACTION_RESET_ALL     0x05

// 8 位修饰键掩码
#define MOD_L_CTRL           (1 << 0)
#define MOD_L_SHIFT          (1 << 1)
#define MOD_L_OPT            (1 << 2)  // Windows 对应 Alt
#define MOD_L_CMD            (1 << 3)  // Windows 对应 Win
#define MOD_R_CTRL           (1 << 4)
#define MOD_R_SHIFT          (1 << 5)
#define MOD_R_OPT            (1 << 6)  // Windows 对应 Alt
#define MOD_R_CMD            (1 << 7)  // Windows 对应 Win

#pragma pack(push, 1)
typedef struct {
    uint32_t magic;      // 0x4D424350 "MBCP" (大端字节序)
    uint8_t  version;    // 1
    uint8_t  action;     // 0x01~0x05
    uint8_t  modifiers;  // 8 位修饰键掩码
    uint8_t  flags;      // 保留 (0)
    uint16_t hid_usage;  // USB HID Usage (大端字节序)
    uint16_t param;      // 脉冲时长 ms (大端字节序)
    uint32_t sequence;   // 递增序号 (大端字节序)
} CompanionPacket;
#pragma pack(pop)

// ==============================================================================
// 2. 修饰键映射结构
// ==============================================================================
typedef struct {
    uint8_t mask;
    WORD vk;
    BOOL extended;
    const char *name;
} ModifierEntry;

static const ModifierEntry MOD_ENTRIES[8] = {
    { MOD_L_CTRL,  VK_LCONTROL, FALSE, "LCtrl" },
    { MOD_L_SHIFT, VK_LSHIFT,   FALSE, "LShift" },
    { MOD_L_OPT,   VK_LMENU,    FALSE, "LAlt" },
    { MOD_L_CMD,   VK_LWIN,     TRUE,  "LWin" },
    { MOD_R_CTRL,  VK_RCONTROL, TRUE,  "RCtrl" },
    { MOD_R_SHIFT, VK_RSHIFT,   FALSE, "RShift" },
    { MOD_R_OPT,   VK_RMENU,    TRUE,  "RAlt" },
    { MOD_R_CMD,   VK_RWIN,     TRUE,  "RWin" },
};

// ==============================================================================
// 3. 全局状态与线程安全锁
// ==============================================================================
static CRITICAL_SECTION g_lock;
static uint8_t g_active_keys[256];     // 记录按下状态 (0 或 1)
static uint8_t g_active_modifiers = 0; // 当前生效的修饰键掩码
static ULONGLONG g_last_packet_time = 0;
static volatile BOOL g_running = TRUE;
static SOCKET g_sock = INVALID_SOCKET;

// ==============================================================================
// 4. HID Usage -> Windows Virtual-Key (VK) 映射
// ==============================================================================
static WORD hid_to_vk(uint16_t hid, BOOL *out_extended) {
    if (out_extended) *out_extended = FALSE;

    // 字母 A-Z (0x0004 ~ 0x001D)
    if (hid >= 0x0004 && hid <= 0x001D) {
        return (WORD)('A' + (hid - 0x0004));
    }

    // 数字 1-9 (0x001E ~ 0x0026)
    if (hid >= 0x001E && hid <= 0x0026) {
        return (WORD)('1' + (hid - 0x001E));
    }
    // 数字 0 (0x0027)
    if (hid == 0x0027) return (WORD)'0';

    // 常用控制键与标点符号
    switch (hid) {
        case 0x0028: return VK_RETURN;
        case 0x0029: return VK_ESCAPE;
        case 0x002A: return VK_BACK;
        case 0x002B: return VK_TAB;
        case 0x002C: return VK_SPACE;
        case 0x002D: return VK_OEM_MINUS;
        case 0x002E: return VK_OEM_PLUS;
        case 0x002F: return VK_OEM_4;       // [
        case 0x0030: return VK_OEM_6;       // ]
        case 0x0031: return VK_OEM_5;       // Backslash (\)
        case 0x0033: return VK_OEM_1;       // ;
        case 0x0034: return VK_OEM_7;       // '
        case 0x0035: return VK_OEM_3;       // `
        case 0x0036: return VK_OEM_COMMA;   // ,
        case 0x0037: return VK_OEM_PERIOD;  // .
        case 0x0038: return VK_OEM_2;       // /
        case 0x0039: return VK_CAPITAL;     // CapsLock
    }

    // 功能键 F1 - F12 (0x003A ~ 0x0045)
    if (hid >= 0x003A && hid <= 0x0045) {
        return (WORD)(VK_F1 + (hid - 0x003A));
    }

    // 导航与控制按键 (大部分为 Extended 扩展键)
    switch (hid) {
        case 0x0046: if (out_extended) *out_extended = TRUE; return VK_SNAPSHOT; // PrintScreen
        case 0x0047: return VK_SCROLL;                                            // ScrollLock
        case 0x0048: return VK_PAUSE;                                             // Pause
        case 0x0049: if (out_extended) *out_extended = TRUE; return VK_INSERT;
        case 0x004A: if (out_extended) *out_extended = TRUE; return VK_HOME;
        case 0x004B: if (out_extended) *out_extended = TRUE; return VK_PRIOR;    // PageUp
        case 0x004C: if (out_extended) *out_extended = TRUE; return VK_DELETE;
        case 0x004D: if (out_extended) *out_extended = TRUE; return VK_END;
        case 0x004E: if (out_extended) *out_extended = TRUE; return VK_NEXT;     // PageDown
        case 0x004F: if (out_extended) *out_extended = TRUE; return VK_RIGHT;
        case 0x0050: if (out_extended) *out_extended = TRUE; return VK_LEFT;
        case 0x0051: if (out_extended) *out_extended = TRUE; return VK_DOWN;
        case 0x0052: if (out_extended) *out_extended = TRUE; return VK_UP;
    }

    // 小键盘数字键区
    switch (hid) {
        case 0x0053: if (out_extended) *out_extended = TRUE; return VK_NUMLOCK;
        case 0x0054: if (out_extended) *out_extended = TRUE; return VK_DIVIDE;
        case 0x0055: return VK_MULTIPLY;
        case 0x0056: return VK_SUBTRACT;
        case 0x0057: return VK_ADD;
        case 0x0058: if (out_extended) *out_extended = TRUE; return VK_RETURN;   // Numpad Enter
        case 0x0059: return VK_NUMPAD1;
        case 0x005A: return VK_NUMPAD2;
        case 0x005B: return VK_NUMPAD3;
        case 0x005C: return VK_NUMPAD4;
        case 0x005D: return VK_NUMPAD5;
        case 0x005E: return VK_NUMPAD6;
        case 0x005F: return VK_NUMPAD7;
        case 0x0060: return VK_NUMPAD8;
        case 0x0061: return VK_NUMPAD9;
        case 0x0062: return VK_NUMPAD0;
        case 0x0063: return VK_DECIMAL;
    }

    // 修饰键 (0x00E0 ~ 0x00E7)
    switch (hid) {
        case 0x00E0: return VK_LCONTROL;
        case 0x00E1: return VK_LSHIFT;
        case 0x00E2: return VK_LMENU;
        case 0x00E3: if (out_extended) *out_extended = TRUE; return VK_LWIN;
        case 0x00E4: if (out_extended) *out_extended = TRUE; return VK_RCONTROL;
        case 0x00E5: return VK_RSHIFT;
        case 0x00E6: if (out_extended) *out_extended = TRUE; return VK_RMENU;
        case 0x00E7: if (out_extended) *out_extended = TRUE; return VK_RWIN;
    }

    return 0; // 未知
}

static BOOL is_vk_extended(WORD vk) {
    switch (vk) {
        case VK_LWIN:
        case VK_RWIN:
        case VK_APPS:
        case VK_RCONTROL:
        case VK_RMENU:
        case VK_INSERT:
        case VK_DELETE:
        case VK_HOME:
        case VK_END:
        case VK_PRIOR:
        case VK_NEXT:
        case VK_LEFT:
        case VK_UP:
        case VK_RIGHT:
        case VK_DOWN:
        case VK_NUMLOCK:
        case VK_DIVIDE:
        case VK_SNAPSHOT:
            return TRUE;
        default:
            return FALSE;
    }
}

// ==============================================================================
// 5. SendInput 键盘事件注入核心
// ==============================================================================
static void send_vk_input(WORD vk, BOOL is_down, BOOL is_extended) {
    INPUT input;
    ZeroMemory(&input, sizeof(INPUT));
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = vk;
    input.ki.wScan = (WORD)MapVirtualKeyW(vk, MAPVK_VK_TO_VSC);
    input.ki.dwFlags = (is_down ? 0 : KEYEVENTF_KEYUP) | (is_extended ? KEYEVENTF_EXTENDEDKEY : 0);
    input.ki.time = 0;
    input.ki.dwExtraInfo = 0;
    SendInput(1, &input, sizeof(INPUT));
}

static void sync_modifiers(uint8_t target_mods) {
    for (int i = 0; i < 8; i++) {
        BOOL should_down = (target_mods & MOD_ENTRIES[i].mask) != 0;
        BOOL is_down = (g_active_modifiers & MOD_ENTRIES[i].mask) != 0;
        if (should_down && !is_down) {
            send_vk_input(MOD_ENTRIES[i].vk, TRUE, MOD_ENTRIES[i].extended);
        } else if (!should_down && is_down) {
            send_vk_input(MOD_ENTRIES[i].vk, FALSE, MOD_ENTRIES[i].extended);
        }
    }
    g_active_modifiers = target_mods;
}

static void get_timestamp(char *buf, size_t max_size) {
    time_t rawtime;
    struct tm *info;
    time(&rawtime);
    info = localtime(&rawtime);
    strftime(buf, max_size, "%H:%M:%S", info);
}

// 紧急安全重置所有按键与修饰键
static void reset_all(const char *reason) {
    EnterCriticalSection(&g_lock);

    char time_str[16];
    get_timestamp(time_str, sizeof(time_str));
    printf("[%s] [Shield] 执行 resetAll (%s)，正在安全释放所有按键...\n", time_str, reason);

    // 释放所有已记录按下的常规键
    for (int vk = 0; vk < 256; vk++) {
        if (g_active_keys[vk]) {
            send_vk_input((WORD)vk, FALSE, is_vk_extended((WORD)vk));
            g_active_keys[vk] = 0;
        }
    }

    // 释放全部 8 个修饰键
    for (int i = 0; i < 8; i++) {
        send_vk_input(MOD_ENTRIES[i].vk, FALSE, MOD_ENTRIES[i].extended);
    }
    g_active_modifiers = 0;
    g_last_packet_time = GetTickCount64();

    LeaveCriticalSection(&g_lock);
    printf("[%s] [OK] 所有按键与修饰键已全部复位释放。\n", time_str);
}

// ==============================================================================
// 6. Pulse 单包脉冲异步处理线程
// ==============================================================================
typedef struct {
    WORD vk;
    BOOL extended;
    DWORD duration_ms;
} PulseContext;

static DWORD WINAPI PulseWorkerThread(LPVOID lpParam) {
    PulseContext *ctx = (PulseContext *)lpParam;
    Sleep(ctx->duration_ms);

    EnterCriticalSection(&g_lock);
    if (g_active_keys[ctx->vk]) {
        g_active_keys[ctx->vk] = 0;
        send_vk_input(ctx->vk, FALSE, ctx->extended);
    }
    LeaveCriticalSection(&g_lock);

    free(ctx);
    return 0;
}

static void trigger_pulse(WORD vk, BOOL extended, uint16_t duration_ms, uint8_t mods) {
    DWORD dur = (duration_ms > 0) ? duration_ms : 50;
    if (dur < 5) dur = 5;
    if (dur > 500) dur = 500;

    EnterCriticalSection(&g_lock);
    g_last_packet_time = GetTickCount64();
    sync_modifiers(mods);
    g_active_keys[vk] = 1;
    send_vk_input(vk, TRUE, extended);
    LeaveCriticalSection(&g_lock);

    PulseContext *ctx = (PulseContext *)malloc(sizeof(PulseContext));
    if (ctx) {
        ctx->vk = vk;
        ctx->extended = extended;
        ctx->duration_ms = dur;
        HANDLE hThread = CreateThread(NULL, 0, PulseWorkerThread, ctx, 0, NULL);
        if (hThread) {
            CloseHandle(hThread);
        } else {
            // 线程创建失败回退同步 Sleep
            Sleep(dur);
            EnterCriticalSection(&g_lock);
            g_active_keys[vk] = 0;
            send_vk_input(vk, FALSE, extended);
            LeaveCriticalSection(&g_lock);
            free(ctx);
        }
    }
}

// ==============================================================================
// 7. 1.5 秒防卡键看门狗线程
// ==============================================================================
static DWORD WINAPI WatchdogThreadProc(LPVOID lpParam) {
    while (g_running) {
        Sleep(100);

        EnterCriticalSection(&g_lock);
        BOOL has_keys = FALSE;
        for (int i = 0; i < 256; i++) {
            if (g_active_keys[i]) {
                has_keys = TRUE;
                break;
            }
        }
        BOOL has_mods = (g_active_modifiers != 0);
        ULONGLONG elapsed = GetTickCount64() - g_last_packet_time;
        LeaveCriticalSection(&g_lock);

        if ((has_keys || has_mods) && elapsed >= 1500) {
            reset_all("看门狗超时 (1.5 秒未收到后续数据包)");
        }
    }
    return 0;
}

// ==============================================================================
// 8. UIPI 管理员提权与防火墙辅助
// ==============================================================================
static BOOL is_admin_elevated(void) {
    BOOL is_elevated = FALSE;
    HANDLE hToken = NULL;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
        TOKEN_ELEVATION elevation;
        DWORD dwSize = sizeof(TOKEN_ELEVATION);
        if (GetTokenInformation(hToken, TokenElevation, &elevation, sizeof(elevation), &dwSize)) {
            is_elevated = (elevation.TokenIsElevated != 0);
        }
        CloseHandle(hToken);
    }
    return is_elevated;
}

static void relaunch_as_admin(int argc, char *argv[]) {
    char exe_path[MAX_PATH];
    GetModuleFileNameA(NULL, exe_path, MAX_PATH);

    // 组装去掉 --elevate / -e 后的剩余参数
    char args_buf[1024] = "";
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--elevate") == 0 || strcmp(argv[i], "-e") == 0) {
            continue;
        }
        strcat(args_buf, "\"");
        strcat(args_buf, argv[i]);
        strcat(args_buf, "\" ");
    }

    HINSTANCE hInst = ShellExecuteA(NULL, "runas", exe_path, args_buf, NULL, SW_SHOWNORMAL);
    if ((INT_PTR)hInst > 32) {
        printf("🚀 已成功请求 UAC 提权启动新实例，原进程退出。\n");
        exit(0);
    } else {
        printf("❌ 请求管理员提权失败 (错误码: %ld)\n", (long)(INT_PTR)hInst);
    }
}

static BOOL add_firewall_rule(int port) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd),
        "netsh advfirewall firewall add rule name=\"MagicBoard Companion UDP %d\" dir=in action=allow protocol=UDP localport=%d",
        port, port);
    printf("🔧 正在执行防火墙规则添加: %s\n", cmd);
    int ret = system(cmd);
    if (ret == 0) {
        printf("✅ Windows 防火墙 UDP 端口 %d 放行规则添加成功。\n", port);
        return TRUE;
    } else {
        printf("❌ 添加防火墙规则失败 (退出码: %d)，请确认已以管理员权限运行。\n", ret);
        return FALSE;
    }
}

static BOOL WINAPI ConsoleCtrlHandler(DWORD dwCtrlType) {
    if (dwCtrlType == CTRL_C_EVENT || dwCtrlType == CTRL_CLOSE_EVENT || dwCtrlType == CTRL_BREAK_EVENT) {
        printf("\n🛑 收到退出信号，正在安全终止服务...\n");
        g_running = FALSE;
        reset_all("服务退出清理");
        if (g_sock != INVALID_SOCKET) {
            closesocket(g_sock);
            g_sock = INVALID_SOCKET;
        }
        return TRUE;
    }
    return FALSE;
}

// ==============================================================================
// 9. 主程序与 UDP 报文分发循环
// ==============================================================================
int main(int argc, char *argv[]) {
    // 设置控制台为 UTF-8 编码并禁用缓冲以便实时捕获日志
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    int port = DEFAULT_PORT;
    const char *log_file = NULL;
    BOOL request_elevate = FALSE;
    BOOL request_firewall = FALSE;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--port") == 0 || strcmp(argv[i], "-p") == 0) {
            if (i + 1 < argc) port = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--log") == 0 || strcmp(argv[i], "-l") == 0) {
            if (i + 1 < argc) log_file = argv[++i];
        } else if (strcmp(argv[i], "--elevate") == 0 || strcmp(argv[i], "-e") == 0) {
            request_elevate = TRUE;
        } else if (strcmp(argv[i], "--add-firewall") == 0) {
            request_firewall = TRUE;
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            printf("MagicBoard Windows 原生伴侣服务\n\n");
            printf("用法:\n");
            printf("  magicboard-companion-win.exe [选项]\n\n");
            printf("选项:\n");
            printf("  -p, --port <port>     指定 UDP 监听端口 (默认: 52088)\n");
            printf("  -l, --log <path>      重定向标准输出与错误到指定日志文件\n");
            printf("  -e, --elevate         若未以管理员运行，自动弹出 UAC 提权窗口\n");
            printf("      --add-firewall    自动添加入站 UDP 防火墙放行规则并退出\n");
            printf("  -h, --help            显示帮助信息\n");
            return 0;
        }
    }

    if (log_file != NULL) {
        FILE *f = freopen(log_file, "a", stdout);
        if (f) {
            freopen(log_file, "a", stderr);
            setvbuf(stdout, NULL, _IONBF, 0);
            setvbuf(stderr, NULL, _IONBF, 0);
        }
    }

    if (request_firewall) {
        return add_firewall_rule(port) ? 0 : 1;
    }

    BOOL admin = is_admin_elevated();
    if (request_elevate && !admin) {
        relaunch_as_admin(argc, argv);
        return 0;
    }

    InitializeCriticalSection(&g_lock);
    memset(g_active_keys, 0, sizeof(g_active_keys));
    g_last_packet_time = GetTickCount64();

    SetConsoleCtrlHandler(ConsoleCtrlHandler, TRUE);

    printf("================================================================\n");
    printf("🎹 MagicBoard Windows 原生伴侣服务 (C 绿色免安装版)\n");
    printf("   协议标准: MBCP v1 (UDP 16-Byte Binary Protocol)\n");
    printf("   监听端口: UDP %d\n", port);
    printf("================================================================\n");

    if (!admin) {
        printf("⚠️ [警告] 当前未以管理员权限运行 (Non-Admin)！\n");
        printf("   受 Windows UIPI 隔离限制，无法向管理员终端、任务管理器等提权窗口注入按键。\n");
        printf("   👉 建议右键以“管理员身份运行”，或启动时附加参数 --elevate 自动触发 UAC 提权。\n");
    } else {
        printf("✅ 管理员权限检测通过 (Admin / High Integrity) - 突破 UIPI 隔离。\n");
    }

    printf("----------------------------------------------------------------\n");
    printf("💡 防火墙配置指引 (若局域网无法连通):\n");
    printf("   pwsh -Command \"New-NetFirewallRule -DisplayName 'MagicBoard Companion' -Direction Inbound -LocalPort %d -Protocol UDP -Action Allow\"\n", port);
    printf("================================================================\n");

    // 初始化 Winsock
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        fprintf(stderr, "❌ WSAStartup 初始化失败: %d\n", WSAGetLastError());
        return 1;
    }

    g_sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (g_sock == INVALID_SOCKET) {
        fprintf(stderr, "❌ 创建 UDP 套接字失败: %d\n", WSAGetLastError());
        WSACleanup();
        return 1;
    }

    BOOL opt_reuse = TRUE;
    setsockopt(g_sock, SOL_SOCKET, SO_REUSEADDR, (const char *)&opt_reuse, sizeof(opt_reuse));

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    server_addr.sin_port = htons((u_short)port);

    if (bind(g_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) == SOCKET_ERROR) {
        fprintf(stderr, "❌ 绑定 UDP 端口 %d 失败: %d\n", port, WSAGetLastError());
        closesocket(g_sock);
        WSACleanup();
        return 1;
    }

    // 启动 1.5s 防卡键看门狗
    HANDLE hWatchdog = CreateThread(NULL, 0, WatchdogThreadProc, NULL, 0, NULL);
    if (hWatchdog) CloseHandle(hWatchdog);

    printf("🚀 MagicBoard 原生伴侣服务已就绪，正在监听 UDP 端口 %d...\n", port);
    printf("💡 提示：按 Ctrl+C 可停止服务，iPad 键盘端输入时将实时捕获并注入。\n");

    uint8_t buffer[1024];
    struct sockaddr_in client_addr;
    int client_addr_len = sizeof(client_addr);

    while (g_running) {
        int n = recvfrom(g_sock, (char *)buffer, sizeof(buffer), 0, (struct sockaddr *)&client_addr, &client_addr_len);
        if (n == SOCKET_ERROR) {
            if (!g_running) break;
            int err = WSAGetLastError();
            if (err == WSAEINTR || err == WSAESHUTDOWN) break;
            continue;
        }

        if (n != PACKET_LENGTH) {
            printf("⚠️ 丢弃非法长度报文: %d 字节\n", n);
            continue;
        }

        CompanionPacket *pkt = (CompanionPacket *)buffer;
        uint32_t magic = ntohl(pkt->magic);
        uint16_t hid_usage = ntohs(pkt->hid_usage);
        uint16_t param = ntohs(pkt->param);
        uint32_t seq = ntohl(pkt->sequence);

        if (magic != PROTOCOL_MAGIC) {
            printf("⚠️ 丢弃非法魔数报文: 0x%08X\n", magic);
            continue;
        }

        if (pkt->version != PROTOCOL_VERSION) {
            printf("⚠️ 丢弃未知协议版本: %d\n", pkt->version);
            continue;
        }

        char time_str[16];
        get_timestamp(time_str, sizeof(time_str));

        // 1. 紧急重置 ResetAll (0x05)
        if (pkt->action == ACTION_RESET_ALL) {
            printf("[%s] 🚨 收到 resetAll 指令 (seq: %lu)，执行安全复位\n", time_str, (unsigned long)seq);
            reset_all("收到客户端 ResetAll 报文");
            continue;
        }

        // 2. 心跳报文 Heartbeat (0x04)
        if (pkt->action == ACTION_HEARTBEAT) {
            EnterCriticalSection(&g_lock);
            g_last_packet_time = GetTickCount64();
            sync_modifiers(pkt->modifiers);
            LeaveCriticalSection(&g_lock);
            continue;
        }

        // 解析 HID Usage
        BOOL is_extended = FALSE;
        WORD vk = hid_to_vk(hid_usage, &is_extended);
        if (vk == 0) {
            printf("[%s] ⚠️ 未知或未映射的 HID Usage: 0x%04X (seq: %lu)\n", time_str, hid_usage, (unsigned long)seq);
            continue;
        }

        // 3. 按键按下 KeyDown (0x01)
        if (pkt->action == ACTION_KEY_DOWN) {
            printf("[%s] ⬇️ KeyDown: HID 0x%04X -> VK 0x%02X, Mods: 0x%02X, Seq: %lu\n",
                time_str, hid_usage, vk, pkt->modifiers, (unsigned long)seq);
            EnterCriticalSection(&g_lock);
            g_last_packet_time = GetTickCount64();
            sync_modifiers(pkt->modifiers);
            g_active_keys[vk] = 1;
            send_vk_input(vk, TRUE, is_extended);
            LeaveCriticalSection(&g_lock);
        }
        // 4. 按键抬起 KeyUp (0x02)
        else if (pkt->action == ACTION_KEY_UP) {
            printf("[%s] ⬆️ KeyUp:   HID 0x%04X -> VK 0x%02X, Mods: 0x%02X, Seq: %lu\n",
                time_str, hid_usage, vk, pkt->modifiers, (unsigned long)seq);
            EnterCriticalSection(&g_lock);
            g_last_packet_time = GetTickCount64();
            sync_modifiers(pkt->modifiers);
            g_active_keys[vk] = 0;
            send_vk_input(vk, FALSE, is_extended);
            LeaveCriticalSection(&g_lock);
        }
        // 5. 单包脉冲 Pulse (0x03)
        else if (pkt->action == ACTION_PULSE) {
            uint16_t dur = (param > 0) ? param : 50;
            printf("[%s] ⚡ Pulse:   HID 0x%04X -> VK 0x%02X, 时长: %dms, Mods: 0x%02X, Seq: %lu\n",
                time_str, hid_usage, vk, dur, pkt->modifiers, (unsigned long)seq);
            trigger_pulse(vk, is_extended, dur, pkt->modifiers);
        }
        else {
            printf("[%s] ⚠️ 未知 Action: 0x%02X (seq: %lu)\n", time_str, pkt->action, (unsigned long)seq);
        }
    }

    reset_all("服务终止");
    if (g_sock != INVALID_SOCKET) {
        closesocket(g_sock);
    }
    WSACleanup();
    DeleteCriticalSection(&g_lock);
    printf("👋 MagicBoard Windows 原生伴侣服务已安全终止。\n");
    return 0;
}
