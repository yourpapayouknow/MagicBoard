// 伴侣Windows原生服务
#include "head.h"

static const ModifierEntry MOD_ENTRIES[8] = {
    { MOD_L_CTRL,  VK_LCONTROL, FALSE },
    { MOD_L_SHIFT, VK_LSHIFT,   FALSE },
    { MOD_L_OPT,   VK_LMENU,    FALSE },
    { MOD_L_CMD,   VK_LWIN,     TRUE  },
    { MOD_R_CTRL,  VK_RCONTROL, TRUE  },
    { MOD_R_SHIFT, VK_RSHIFT,   FALSE },
    { MOD_R_OPT,   VK_RMENU,    TRUE  },
    { MOD_R_CMD,   VK_RWIN,     TRUE  },
};

static CRITICAL_SECTION g_lock;
static uint8_t g_active_keys[256];
static uint8_t g_active_modifiers = 0;
static ULONGLONG g_last_packet_time = 0;
static volatile BOOL g_running = TRUE;
static SOCKET g_sock = INVALID_SOCKET;

// 转换键码
static WORD hidtovk(uint16_t hid, BOOL *out_extended) {
    if (out_extended) *out_extended = FALSE;

    if (hid >= 0x0004 && hid <= 0x001D) {
        return (WORD)('A' + (hid - 0x0004));
    }

    if (hid >= 0x001E && hid <= 0x0026) {
        return (WORD)('1' + (hid - 0x001E));
    }
    if (hid == 0x0027) return (WORD)'0';

    switch (hid) {
        case 0x0028: return VK_RETURN;
        case 0x0029: return VK_ESCAPE;
        case 0x002A: return VK_BACK;
        case 0x002B: return VK_TAB;
        case 0x002C: return VK_SPACE;
        case 0x002D: return VK_OEM_MINUS;
        case 0x002E: return VK_OEM_PLUS;
        case 0x002F: return VK_OEM_4;
        case 0x0030: return VK_OEM_6;
        case 0x0031: return VK_OEM_5;
        case 0x0033: return VK_OEM_1;
        case 0x0034: return VK_OEM_7;
        case 0x0035: return VK_OEM_3;
        case 0x0036: return VK_OEM_COMMA;
        case 0x0037: return VK_OEM_PERIOD;
        case 0x0038: return VK_OEM_2;
        case 0x0039: return VK_CAPITAL;
    }

    if (hid >= 0x003A && hid <= 0x0045) {
        return (WORD)(VK_F1 + (hid - 0x003A));
    }

    switch (hid) {
        case 0x0046: if (out_extended) *out_extended = TRUE; return VK_SNAPSHOT;
        case 0x0047: return VK_SCROLL;
        case 0x0048: return VK_PAUSE;
        case 0x0049: if (out_extended) *out_extended = TRUE; return VK_INSERT;
        case 0x004A: if (out_extended) *out_extended = TRUE; return VK_HOME;
        case 0x004B: if (out_extended) *out_extended = TRUE; return VK_PRIOR;
        case 0x004C: if (out_extended) *out_extended = TRUE; return VK_DELETE;
        case 0x004D: if (out_extended) *out_extended = TRUE; return VK_END;
        case 0x004E: if (out_extended) *out_extended = TRUE; return VK_NEXT;
        case 0x004F: if (out_extended) *out_extended = TRUE; return VK_RIGHT;
        case 0x0050: if (out_extended) *out_extended = TRUE; return VK_LEFT;
        case 0x0051: if (out_extended) *out_extended = TRUE; return VK_DOWN;
        case 0x0052: if (out_extended) *out_extended = TRUE; return VK_UP;
    }

    switch (hid) {
        case 0x0053: if (out_extended) *out_extended = TRUE; return VK_NUMLOCK;
        case 0x0054: if (out_extended) *out_extended = TRUE; return VK_DIVIDE;
        case 0x0055: return VK_MULTIPLY;
        case 0x0056: return VK_SUBTRACT;
        case 0x0057: return VK_ADD;
        case 0x0058: if (out_extended) *out_extended = TRUE; return VK_RETURN;
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

    return 0;
}

// 检查扩展键
static BOOL isvkext(WORD vk) {
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

// 发送按键
static void sndvk(WORD vk, BOOL is_down, BOOL is_extended) {
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

// 同步修饰键
static void syncmod(uint8_t target_mods) {
    for (int i = 0; i < 8; i++) {
        BOOL should_down = (target_mods & MOD_ENTRIES[i].mask) != 0;
        BOOL is_down = (g_active_modifiers & MOD_ENTRIES[i].mask) != 0;
        if (should_down && !is_down) {
            sndvk(MOD_ENTRIES[i].vk, TRUE, MOD_ENTRIES[i].extended);
        } else if (!should_down && is_down) {
            sndvk(MOD_ENTRIES[i].vk, FALSE, MOD_ENTRIES[i].extended);
        }
    }
    g_active_modifiers = target_mods;
}

// 获取时间戳
static void getts(char *buf, size_t max_size) {
    time_t rawtime;
    struct tm *info;
    time(&rawtime);
    info = localtime(&rawtime);
    strftime(buf, max_size, "%H:%M:%S", info);
}

// 重置按键
static void rstall(const char *reason) {
    EnterCriticalSection(&g_lock);

    char time_str[16];
    getts(time_str, sizeof(time_str));
    printf("[%s] 执行 rstall (%s)\n", time_str, reason);

    for (int vk = 0; vk < 256; vk++) {
        if (g_active_keys[vk]) {
            sndvk((WORD)vk, FALSE, isvkext((WORD)vk));
            g_active_keys[vk] = 0;
        }
    }

    for (int i = 0; i < 8; i++) {
        sndvk(MOD_ENTRIES[i].vk, FALSE, MOD_ENTRIES[i].extended);
    }
    g_active_modifiers = 0;
    g_last_packet_time = GetTickCount64();

    LeaveCriticalSection(&g_lock);
}

// 脉冲线程
static DWORD WINAPI plsrun(LPVOID lpParam) {
    PulseContext *ctx = (PulseContext *)lpParam;
    Sleep(ctx->duration_ms);

    EnterCriticalSection(&g_lock);
    if (g_active_keys[ctx->vk]) {
        g_active_keys[ctx->vk] = 0;
        sndvk(ctx->vk, FALSE, ctx->extended);
    }
    LeaveCriticalSection(&g_lock);

    free(ctx);
    return 0;
}

// 触发脉冲
static void trigpls(WORD vk, BOOL extended, uint16_t duration_ms, uint8_t mods) {
    DWORD dur = (duration_ms > 0) ? duration_ms : 50;
    if (dur < 5) dur = 5;
    if (dur > 500) dur = 500;

    EnterCriticalSection(&g_lock);
    g_last_packet_time = GetTickCount64();
    syncmod(mods);
    g_active_keys[vk] = 1;
    sndvk(vk, TRUE, extended);
    LeaveCriticalSection(&g_lock);

    PulseContext *ctx = (PulseContext *)malloc(sizeof(PulseContext));
    if (ctx) {
        ctx->vk = vk;
        ctx->extended = extended;
        ctx->duration_ms = dur;
        HANDLE hThread = CreateThread(NULL, 0, plsrun, ctx, 0, NULL);
        if (hThread) {
            CloseHandle(hThread);
        } else {
            Sleep(dur);
            EnterCriticalSection(&g_lock);
            g_active_keys[vk] = 0;
            sndvk(vk, FALSE, extended);
            LeaveCriticalSection(&g_lock);
            free(ctx);
        }
    }
}

// 看门狗线程
static DWORD WINAPI wtdgrun(LPVOID lpParam) {
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
            rstall("看门狗超时");
        }
    }
    return 0;
}

// 检测提权
static BOOL isadmin(void) {
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

// 请求提权
static void reqadmin(int argc, char *argv[]) {
    char exe_path[MAX_PATH];
    GetModuleFileNameA(NULL, exe_path, MAX_PATH);

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
        exit(0);
    }
}

// 添加防火墙规则
static BOOL addfw(int port) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd),
        "netsh advfirewall firewall add rule name=\"MagicBoard Companion UDP %d\" dir=in action=allow protocol=UDP localport=%d",
        port, port);
    return system(cmd) == 0;
}

// 控制台信号处理
static BOOL WINAPI ctrlhndl(DWORD dwCtrlType) {
    if (dwCtrlType == CTRL_C_EVENT || dwCtrlType == CTRL_CLOSE_EVENT || dwCtrlType == CTRL_BREAK_EVENT) {
        g_running = FALSE;
        rstall("服务退出清理");
        if (g_sock != INVALID_SOCKET) {
            closesocket(g_sock);
            g_sock = INVALID_SOCKET;
        }
        return TRUE;
    }
    return FALSE;
}

// 主函数
int main(int argc, char *argv[]) {
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
            printf("用法: cpwin.exe [选项]\n");
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
        return addfw(port) ? 0 : 1;
    }

    BOOL admin = isadmin();
    if (request_elevate && !admin) {
        reqadmin(argc, argv);
        return 0;
    }

    InitializeCriticalSection(&g_lock);
    memset(g_active_keys, 0, sizeof(g_active_keys));
    g_last_packet_time = GetTickCount64();

    SetConsoleCtrlHandler(ctrlhndl, TRUE);

    printf("MagicBoard Windows 伴侣服务已启动，端口: %d\n", port);

    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        return 1;
    }

    g_sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (g_sock == INVALID_SOCKET) {
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
        closesocket(g_sock);
        WSACleanup();
        return 1;
    }

    HANDLE hWatchdog = CreateThread(NULL, 0, wtdgrun, NULL, 0, NULL);
    if (hWatchdog) CloseHandle(hWatchdog);

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
            continue;
        }

        CompanionPacket *pkt = (CompanionPacket *)buffer;
        uint32_t magic = ntohl(pkt->magic);
        uint16_t hid_usage = ntohs(pkt->hid_usage);
        uint16_t param = ntohs(pkt->param);
        uint32_t seq = ntohl(pkt->sequence);

        if (magic != PROTOCOL_MAGIC || pkt->version != PROTOCOL_VERSION) {
            continue;
        }

        char time_str[16];
        getts(time_str, sizeof(time_str));

        if (pkt->action == ACTION_RESET_ALL) {
            rstall("收到 resetAll 报文");
            continue;
        }

        if (pkt->action == ACTION_HEARTBEAT) {
            EnterCriticalSection(&g_lock);
            g_last_packet_time = GetTickCount64();
            syncmod(pkt->modifiers);
            LeaveCriticalSection(&g_lock);
            continue;
        }

        BOOL is_extended = FALSE;
        WORD vk = hidtovk(hid_usage, &is_extended);
        if (vk == 0) {
            continue;
        }

        if (pkt->action == ACTION_KEY_DOWN) {
            printf("[%s] ⬇️ KeyDown: 0x%04X (seq: %lu)\n", time_str, hid_usage, (unsigned long)seq);
            EnterCriticalSection(&g_lock);
            g_last_packet_time = GetTickCount64();
            syncmod(pkt->modifiers);
            g_active_keys[vk] = 1;
            sndvk(vk, TRUE, is_extended);
            LeaveCriticalSection(&g_lock);
        } else if (pkt->action == ACTION_KEY_UP) {
            printf("[%s] ⬆️ KeyUp: 0x%04X (seq: %lu)\n", time_str, hid_usage, (unsigned long)seq);
            EnterCriticalSection(&g_lock);
            g_last_packet_time = GetTickCount64();
            syncmod(pkt->modifiers);
            g_active_keys[vk] = 0;
            sndvk(vk, FALSE, is_extended);
            LeaveCriticalSection(&g_lock);
        } else if (pkt->action == ACTION_PULSE) {
            uint16_t dur = (param > 0) ? param : 50;
            printf("[%s] ⚡ Pulse: 0x%04X (%dms, seq: %lu)\n", time_str, hid_usage, dur, (unsigned long)seq);
            trigpls(vk, is_extended, dur, pkt->modifiers);
        }
    }

    rstall("服务终止");
    if (g_sock != INVALID_SOCKET) {
        closesocket(g_sock);
    }
    WSACleanup();
    DeleteCriticalSection(&g_lock);
    return 0;
}
