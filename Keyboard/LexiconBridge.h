#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^MBLexiconCompletion)(NSDictionary<NSString *, NSArray<NSString *> *> *entries);

// 桥接系统补充词典的后台回调
@interface MBLexiconBridge : NSObject

// 读取并整理系统补充词典
+ (void)load:(UIInputViewController *)controller completion:(MBLexiconCompletion)completion;

@end

NS_ASSUME_NONNULL_END
