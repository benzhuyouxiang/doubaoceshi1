#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"
#import "UI/DVMenuController.h"

// 所有要用的 selector 必须先声明，Logos 预处理才认得
@interface DVMenuTarget : NSObject
+ (instancetype)shared;
- (void)dvRead:(id)sender;
- (NSString *)dv_selectedText;
- (UIResponder *)dv_findResponder;
@end

@interface NSObject (DVMenuActions)
- (void)dvRead:(id)sender;
@end

@implementation DVMenuTarget

+ (instancetype)shared {
    static DVMenuTarget *t = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ t = [DVMenuTarget new]; });
    return t;
}

- (UIResponder *)dv_findOne:(UIView *)v {
    if (v.isFirstResponder) return v;
    for (UIView *sub in v.subviews) {
        UIResponder *r = [self dv_findOne:sub];
        if (r) return r;
    }
    return nil;
}

- (UIResponder *)dv_findResponder {
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        UIResponder *r = [self dv_findOne:w];
        if (r) return r;
    }
    return nil;
}

- (NSString *)dv_selectedText {
    UIResponder *r = [self dv_findResponder];
    if (!r) return nil;
    @try {
        if ([r isKindOfClass:[UITextView class]]) {
            UITextView *tv = (UITextView *)r;
            UITextRange *range = tv.selectedTextRange;
            if (range) {
                NSString *s = [tv textInRange:range];
                if (s.length) return s;
            }
            return tv.text;
        }
        if ([r isKindOfClass:[UITextField class]]) {
            UITextField *tf = (UITextField *)r;
            UITextRange *range = tf.selectedTextRange;
            if (range) {
                NSString *s = [tf textInRange:range];
                if (s.length) return s;
            }
            return tf.text;
        }
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] 取文字异常 %@", e.reason);
    }
    return nil;
}

- (void)dvRead:(id)sender {
    NSLog(@"[豆包语音] 点了朗读");
    NSString *txt = [self dv_selectedText];
    if (txt.length == 0) {
        txt = objc_getAssociatedObject([UIMenuController sharedMenuController],
                                       "dv_last_text");
    }
    txt = [txt stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (txt.length == 0) {
        [DVHUD showError:@"没拿到文字"];
        return;
    }
    NSLog(@"[豆包语音] 朗读 %lu 字", (unsigned long)txt.length);
    [DVMenuController readText:txt];
}

@end

#pragma mark - 往菜单加一项

static void dv_add_menu_items(void) {
    @try {
        UIMenuController *mc = [UIMenuController sharedMenuController];
        NSArray *old = mc.menuItems;
        NSMutableArray *arr = [NSMutableArray array];
        for (UIMenuItem *it in old) {
            if ([it.title isEqualToString:@"豆包朗读"]) continue;
            [arr addObject:it];
        }
        [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包朗读"
                                                  action:@selector(dvRead:)]];
        mc.menuItems = arr;
        NSLog(@"[豆包语音] 菜单已写入 %lu 项", (unsigned long)arr.count);
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] 写菜单异常 %@", e.reason);
    }
}

#pragma mark - hook UIMenuController

%hook UIMenuController

- (void)setMenuItems:(NSArray *)items {
    NSMutableArray *arr = [NSMutableArray array];
    BOOL hasRead = NO;
    for (UIMenuItem *it in items) {
        if ([it.title isEqualToString:@"豆包朗读"]) { hasRead = YES; continue; }
        [arr addObject:it];
    }
    if (!hasRead) {
        [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包朗读"
                                                  action:@selector(dvRead:)]];
    }
    %orig(arr);
}

- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated {
    if (visible) {
        @try {
            NSString *t = [[DVMenuTarget shared] dv_selectedText];
            if (t.length) {
                objc_setAssociatedObject([UIMenuController sharedMenuController],
                                         "dv_last_text", t,
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        } @catch (NSException *e) {}
    }
    %orig;
}

%end

#pragma mark - 让菜单项可点

%hook UIResponder

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(dvRead:)) {
        return YES;
    }
    return %orig;
}

%end

#pragma mark - 启动

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] v2.0.1 已加载 pid=%d", getpid());
        [DVStore shared];
        dv_add_menu_items();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"豆包语音已就绪"];
        });
    }
}
