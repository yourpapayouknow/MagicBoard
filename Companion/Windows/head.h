// 统一头文件
#ifndef HEAD_H
#define HEAD_H

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

#define PROTOCOL_MAGIC       0x4D424350
#define PROTOCOL_VERSION     1
#define PACKET_LENGTH        16
#define DEFAULT_PORT         52088

#define ACTION_KEY_DOWN      0x01
#define ACTION_KEY_UP        0x02
#define ACTION_PULSE         0x03
#define ACTION_HEARTBEAT     0x04
#define ACTION_RESET_ALL     0x05

#define MOD_L_CTRL           (1 << 0)
#define MOD_L_SHIFT          (1 << 1)
#define MOD_L_OPT            (1 << 2)
#define MOD_L_CMD            (1 << 3)
#define MOD_R_CTRL           (1 << 4)
#define MOD_R_SHIFT          (1 << 5)
#define MOD_R_OPT            (1 << 6)
#define MOD_R_CMD            (1 << 7)

#pragma pack(push, 1)
// 报文结构
typedef struct {
    uint32_t magic;
    uint8_t  version;
    uint8_t  action;
    uint8_t  modifiers;
    uint8_t  flags;
    uint16_t hid_usage;
    uint16_t param;
    uint32_t sequence;
} CompanionPacket;
#pragma pack(pop)

// 修饰键映射结构
typedef struct {
    uint8_t mask;
    WORD vk;
    BOOL extended;
} ModifierEntry;

// 脉冲上下文
typedef struct {
    WORD vk;
    BOOL extended;
    DWORD duration_ms;
} PulseContext;

#endif
