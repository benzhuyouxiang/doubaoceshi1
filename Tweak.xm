#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"
#import "UI/DVMenuController.h"

#pragma mark - 菜单动作（必须在 @interface 里声明）

@interface DVMenuTarget : NSObject
+ (instancetype)shared;
- (void)dvRead:(id)sender;
- (void)dvStop:(id)sender;
- (void)dvSettings:(id)sender;
@end

@implementation DVMenuTarget

+ (instancetype)shared {
    static DVMenuTarget *t = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ t = [DVMenuTarget new]; });
    return t;
}

#pragma mark 找当前响应者

- (UIResponder *)dv_findResponder {
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        UIResponder *r = [self dv_findIn:w];
        if (r) return r;
    }
    return nil;
}

- (UIResponder *)dv_findIn:(UIView *)v {
    if (v.isFirstResponder) return v;
    for (UIView *sub in v.subviews) {
        UIResponder *r = [self dv_findIn:sub];
        if (r) return r;
    }
    return nil;
}

#pragma mark 从响应者取被选中的文字

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

#pragma mark 三个动作

- (void)dvRead:(id)sender {
    NSLog(@"[豆包语音] 点击朗读 sender=%@", NSStringFromClass([sender class]));

    NSString *txt = [self dv_selectedText];

    // 拿不到就退回到最近一次长按的缓存
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

    NSLog(@"[豆包语音] 开始朗读 %lu 字", (unsigned long)txt.length);
    [DVMenuController readText:txt];
}

- (void)dvStop:(id)sender {
    [DVMenuController stopSpeaking];
}

- (void)dvSettings:(id)sender {
    UIViewController *host = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) { host = w.rootViewController; break; }
    }
    while (host.presentedViewController) host = host.presentedViewController;
    [DVMenuController openSettingsFrom:host];
}

@end

#pragma mark - 往菜单里塞项

static void dv_add_menu_items(void) {
    @try {
        UIMenuController *mc = [UIMenuController sharedMenuController];
        NSArray *old = mc.menuItems;
        NSMutableArray *arr = [NSMutableArray array];

        // 保留别人的项（锤子助手等），只去掉我们自己的
        for (UIMenuItem *it in old) {
            NSString *t = it.title;
            if ([t isEqualToString:@"豆包朗讀"] || [t isEqualToString:@"豆包朗读"] ||
                [t isEqualToString:@"豆包停止"] || [t isEqualToString:@"豆包設置"] ||
                [t isEqualToString:@"豆包设置"]) {
                continue;
            }
            [arr addObject:it];
        }

        [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包朗讀"
                                                  action:@selector(dvRead:)]];
        [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包停止"
                                                  action:@selector(dvStop:)]];
        [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包設置"
                                                  action:@selector(dvSettings:)]];

        mc.menuItems = arr;
        NSLog(@"[豆包语音] 菜单项写入，共 %lu 项", (unsigned long)arr.count);
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] 写菜单异常 %@", e.reason);
    }
}

#pragma mark - hook：每次 setMenuItems 都追加

%hook UIMenuController

- (void)setMenuItems:(NSArray *)items {
    @try {
        NSMutableArray *arr = [NSMutableArray array];
        BOOL hasRead = NO, hasStop = NO, hasSet = NO;

        for (UIMenuItem *it in items) {
            NSString *t = it.title;
            if ([t isEqualToString:@"豆包朗讀"] || [t isEqualToString:@"豆包朗读"]) {
                hasRead = YES;
                continue;
            }
            if ([t isEqualToString:@"豆包停止"]) { hasStop = YES; continue; }
            if ([t isEqualToString:@"豆包設置"] || [t isEqualToString:@"豆包设置"]) {
                hasSet = YES;
                continue;
            }
            [arr addObject:it];
        }

        if (!hasRead) {
            [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包朗讀"
                                                      action:@selector(dvRead:)]];
        }
        if (!hasStop) {
            [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包停止"
                                                      action:@selector(dvStop:)]];
        }
        if (!hasSet) {
            [arr addObject:[[UIMenuItem alloc] initWithTitle:@"豆包設置"
                                                      action:@selector(dvSettings:)]];
        }

        %orig(arr);
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] setMenuItems 异常 %@", e.reason);
        %orig;
    }
}

- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated {
    @try {
        // 菜单要显示时，把当前选中的文字缓存起来
        if (visible) {
            NSString *t = [[DVMenuTarget shared] dv_selectedText];
            if (t.length == 0) {
                t = objc_getAssociatedObject([UIMenuController sharedMenuController],
                                             "dv_last_text");
            }
            if (t.length) {
                objc_setAssociatedObject([UIMenuController sharedMenuController],
                                         "dv_last_text", t,
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    } @catch (NSException *e) {}
    %orig;
}

%end

#pragma mark - hook：让菜单项可点

%hook UIResponder

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(dvRead:) ||
        action == @selector(dvStop:) ||
        action == @selector(dvSettings:)) {
        return YES;
    }
    return %orig;
}

%end

#pragma mark - hook UILabel：把 label 的文字也缓存下来

%hook UILabel

- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) return;
        // 只是让菜单有东西可读，不挂手势
    } @catch (NSException *e) {}
}

%end

#pragma mark - 启动

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] v2.0.0 菜单版 已加载 pid=%d", getpid());
        [DVStore shared];
        dv_add_menu_items();

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"豆包语音已就绪"];
        });
    }
}
