// 向 Swift 键盘控制器暴露 HID 特殊键发送接口
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 标识 MagicBoard 支持的 USB HID 键
typedef NS_ENUM(uint32_t, MBHIDKey) {
    MBHIDKeyEscape = 0x29,
    MBHIDKeyRightArrow = 0x4F,
    MBHIDKeyLeftArrow = 0x50,
    MBHIDKeyDownArrow = 0x51,
    MBHIDKeyUpArrow = 0x52,
};

// 管理 TrollStore HID 事件客户端
@interface HIDBridge : NSObject

@property(class, nonatomic, readonly) HIDBridge *shared;
@property(nonatomic, readonly, getter=isAvailable) BOOL available;

// 发送按键按下事件
- (BOOL)keyDown:(MBHIDKey)key;

// 发送按键抬起事件
- (BOOL)keyUp:(MBHIDKey)key;

// 释放全部仍处于按下状态的按键
- (void)releaseAll;

@end

NS_ASSUME_NONNULL_END
