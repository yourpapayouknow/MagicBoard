// 向 Swift 键盘控制器暴露 HID 特殊键发送接口
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 标识 MagicBoard 支持的 USB HID 键
typedef NS_ENUM(uint32_t, MBHIDKey) {
    MBHIDKeyA = 0x04,
    MBHIDKeyB = 0x05,
    MBHIDKeyC = 0x06,
    MBHIDKeyD = 0x07,
    MBHIDKeyE = 0x08,
    MBHIDKeyF = 0x09,
    MBHIDKeyG = 0x0A,
    MBHIDKeyH = 0x0B,
    MBHIDKeyI = 0x0C,
    MBHIDKeyJ = 0x0D,
    MBHIDKeyK = 0x0E,
    MBHIDKeyL = 0x0F,
    MBHIDKeyM = 0x10,
    MBHIDKeyN = 0x11,
    MBHIDKeyO = 0x12,
    MBHIDKeyP = 0x13,
    MBHIDKeyQ = 0x14,
    MBHIDKeyR = 0x15,
    MBHIDKeyS = 0x16,
    MBHIDKeyT = 0x17,
    MBHIDKeyU = 0x18,
    MBHIDKeyV = 0x19,
    MBHIDKeyW = 0x1A,
    MBHIDKeyX = 0x1B,
    MBHIDKeyY = 0x1C,
    MBHIDKeyZ = 0x1D,
    MBHIDKeyDigit1 = 0x1E,
    MBHIDKeyDigit2 = 0x1F,
    MBHIDKeyDigit3 = 0x20,
    MBHIDKeyDigit4 = 0x21,
    MBHIDKeyDigit5 = 0x22,
    MBHIDKeyDigit6 = 0x23,
    MBHIDKeyDigit7 = 0x24,
    MBHIDKeyDigit8 = 0x25,
    MBHIDKeyDigit9 = 0x26,
    MBHIDKeyDigit0 = 0x27,
    MBHIDKeyEnter = 0x28,
    MBHIDKeyEscape = 0x29,
    MBHIDKeyDelete = 0x2A,
    MBHIDKeySpace = 0x2C,
    MBHIDKeyMinus = 0x2D,
    MBHIDKeyEqual = 0x2E,
    MBHIDKeyLeftBracket = 0x2F,
    MBHIDKeyRightBracket = 0x30,
    MBHIDKeyBackslash = 0x31,
    MBHIDKeySemicolon = 0x33,
    MBHIDKeyQuote = 0x34,
    MBHIDKeyGrave = 0x35,
    MBHIDKeyComma = 0x36,
    MBHIDKeyPeriod = 0x37,
    MBHIDKeySlash = 0x38,
    MBHIDKeyRightArrow = 0x4F,
    MBHIDKeyLeftArrow = 0x50,
    MBHIDKeyDownArrow = 0x51,
    MBHIDKeyUpArrow = 0x52,
    MBHIDKeyControl = 0xE0,
    MBHIDKeyLeftShift = 0xE1,
    MBHIDKeyLeftOption = 0xE2,
    MBHIDKeyLeftCommand = 0xE3,
    MBHIDKeyRightShift = 0xE5,
    MBHIDKeyRightOption = 0xE6,
    MBHIDKeyRightCommand = 0xE7,
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
