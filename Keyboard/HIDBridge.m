// 通过 IOKit 私有 HID API 派发实体键盘事件
#import "HIDBridge.h"

#import <CoreFoundation/CoreFoundation.h>
#import <mach/mach_time.h>

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;

extern IOHIDEventRef IOHIDEventCreateKeyboardEvent(
    CFAllocatorRef allocator,
    uint64_t timestamp,
    uint32_t usagePage,
    uint32_t usage,
    Boolean isKeyDown,
    uint32_t options
);
extern void IOHIDEventSetSenderID(IOHIDEventRef event, uint64_t senderID);
extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
extern void IOHIDEventSystemClientDispatchEvent(IOHIDEventSystemClientRef client, IOHIDEventRef event);

static const uint32_t MBHIDKeyboardPage = 0x07;
static const uint64_t MBHIDSenderID = 0x8000000817319371;

// 合成活动键唯一标识
static uint64_t MBHIDToken(uint32_t page, uint32_t usage) {
    return ((uint64_t)page << 32) | usage;
}

// 解析系统功能键的 usage page
static uint32_t MBHIDSystemPage(MBHIDSystemKey key) {
    return ((uint32_t)key >> 16) & 0xFFFF;
}

// 解析系统功能键的 usage
static uint32_t MBHIDSystemUsage(MBHIDSystemKey key) {
    return (uint32_t)key & 0xFFFF;
}

@interface HIDBridge ()

@property(nonatomic) IOHIDEventSystemClientRef client;
@property(nonatomic) dispatch_queue_t queue;
@property(nonatomic) NSMutableSet<NSNumber *> *activeKeys;

@end

@implementation HIDBridge

// 创建共享 HID 客户端
+ (HIDBridge *)shared {
    static HIDBridge *bridge;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bridge = [[HIDBridge alloc] init];
    });
    return bridge;
}

// 初始化串行事件通道
- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.iwmei.magicboard.hid", DISPATCH_QUEUE_SERIAL);
        _activeKeys = [NSMutableSet set];
        _client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    }
    return self;
}

// 判断 HID 客户端是否可用
- (BOOL)isAvailable {
    return self.client != NULL;
}

// 发送按键按下事件
- (BOOL)keyDown:(MBHIDKey)key {
    return [self sendPage:MBHIDKeyboardPage usage:key isKeyDown:YES];
}

// 发送按键抬起事件
- (BOOL)keyUp:(MBHIDKey)key {
    return [self sendPage:MBHIDKeyboardPage usage:key isKeyDown:NO];
}

// 发送系统功能键按下事件
- (BOOL)systemKeyDown:(MBHIDSystemKey)key {
    return [self sendPage:MBHIDSystemPage(key) usage:MBHIDSystemUsage(key) isKeyDown:YES];
}

// 发送系统功能键抬起事件
- (BOOL)systemKeyUp:(MBHIDSystemKey)key {
    return [self sendPage:MBHIDSystemPage(key) usage:MBHIDSystemUsage(key) isKeyDown:NO];
}

// 释放全部仍处于按下状态的按键
- (void)releaseAll {
    if (!self.available) {
        return;
    }
    dispatch_sync(self.queue, ^{
        NSArray<NSNumber *> *keys = self.activeKeys.allObjects;
        for (NSNumber *key in keys) {
            uint64_t token = key.unsignedLongLongValue;
            uint32_t page = (uint32_t)(token >> 32);
            uint32_t usage = (uint32_t)token;
            [self dispatchPage:page usage:usage isKeyDown:NO];
        }
        [self.activeKeys removeAllObjects];
    });
}

// 串行更新按键状态并派发事件
- (BOOL)sendPage:(uint32_t)page usage:(uint32_t)usage isKeyDown:(BOOL)isKeyDown {
    if (!self.available) {
        return NO;
    }

    __block BOOL sent = NO;
    dispatch_sync(self.queue, ^{
        NSNumber *keyValue = @(MBHIDToken(page, usage));
        BOOL active = [self.activeKeys containsObject:keyValue];
        if ((isKeyDown && active) || (!isKeyDown && !active)) {
            sent = YES;
            return;
        }
        sent = [self dispatchPage:page usage:usage isKeyDown:isKeyDown];
        if (!sent) {
            return;
        }
        if (isKeyDown) {
            [self.activeKeys addObject:keyValue];
        } else {
            [self.activeKeys removeObject:keyValue];
        }
    });
    return sent;
}

// 创建并派发单个 HID 事件
- (BOOL)dispatchPage:(uint32_t)page usage:(uint32_t)usage isKeyDown:(BOOL)isKeyDown {
    IOHIDEventRef event = IOHIDEventCreateKeyboardEvent(
        kCFAllocatorDefault,
        mach_absolute_time(),
        page,
        usage,
        isKeyDown,
        0
    );
    if (event == NULL) {
        return NO;
    }
    IOHIDEventSetSenderID(event, MBHIDSenderID);
    IOHIDEventSystemClientDispatchEvent(self.client, event);
    CFRelease(event);
    return YES;
}

@end
