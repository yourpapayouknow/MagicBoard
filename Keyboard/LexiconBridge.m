#import "LexiconBridge.h"
#import <dispatch/dispatch.h>

@implementation MBLexiconBridge

// 读取并整理系统补充词典
+ (void)load:(UIInputViewController *)controller completion:(MBLexiconCompletion)completion {
    [controller requestSupplementaryLexiconWithCompletion:^(UILexicon *value) {
        NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *grouped = [NSMutableDictionary dictionary];
        for (UILexiconEntry *entry in value.entries) {
            NSString *key = entry.userInput.lowercaseString;
            if (key.length == 0 || entry.documentText.length == 0) {
                continue;
            }
            NSMutableArray<NSString *> *items = grouped[key];
            if (items == nil) {
                items = [NSMutableArray array];
                grouped[key] = items;
            }
            if (![items containsObject:entry.documentText]) {
                [items addObject:entry.documentText];
            }
        }
        NSDictionary<NSString *, NSArray<NSString *> *> *result = [grouped copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result);
        });
    }];
}

@end
