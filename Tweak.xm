#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "TTS/DVProtocol.h"
#import "TTS/DVTTSEngine.h"
#import "UI/DVHUD.h"
#import "UI/DVMenuController.h"
#import "UI/DVMoreInjector.h"
#import "Prefs/DVStore.h"
#import "Prefs/DVSettingsController.h"

@interface WCMoreFunctionViewController : UIViewController
@end

@interface WCMoreViewController : UIViewController
@end

@interface MMGrowTextView : UIView
@end

static const void *kDVTapKey = &kDVTapKey;

#pragma mark - 取文字

static NSString *dv_text_of(UIView *view) {
    if (!view) return nil;
    @try {
        if ([view isKindOfClass:[UITextView class]]) {
            UITextView *tv = (UITextView *)view;
            UITextRange *r = tv.selectedTextRange;
            if (r) {
                NSString *sel = [tv textInRange:r];
                if (sel.length) return sel;
            }
            return tv.text;
        }
        if ([view isKindOfClass:[UITextField class]]) {
            return ((UITextField *)view).text;
        }
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *lb = (UILabel *)view;
            NSAttributedString *at = lb.attributedText;
            if (at.length) return at.string;
            return lb.text;
        }
        if ([view respondsToSelector:@selector(text)]) {
            id t = [view performSelector:@selector(text)];
            if ([t isKindOfClass:[NSString class]] && [(NSString *)t length]) return t;
        }
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] dv_text_of 异常 %@", e.reason);
    }
    return nil;
}

#pragma mark - 判断

static BOOL dv_ok(UIView *view) {
    if (!view) return NO;
    if (view.window == nil) return NO;
    @try {
        CGRect f = view.frame;
        if (f.size.height < 10 || f.size.width < 24) return NO;

        NSString *cn = NSStringFromClass([view class]);
        if ([cn containsString:@"Button"]) return NO;
        if ([cn containsString:@"NavigationBar"]) return NO;
        if ([cn containsString:@"TabBar"]) return NO;
        if ([cn containsString:@"Keyboard"]) return NO;
        if ([cn containsString:@"SearchBar"]) return NO;

        NSString *txt = dv_text_of(view);
        if (txt.length < 1) return NO;
        return YES;
    } @catch (NSException *e) {
        return NO;
    }
}

#pragma mark - 长按处理

static void dv_on_long_press(UIView *view, UIGestureRecognizer *g) {
    if (g.state != UIGestureRecognizerStateBegan) return;

    NSString *txt = dv_text_of(view);
    txt = [txt stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (txt.length == 0) return;
    if (txt.length > 4000) txt = [txt substringToIndex:4000];

    UIViewController *host = view.window.rootViewController;
    while (host.presentedViewController) host = host.presentedViewController;
    if (!host) return;

    [DVMenuController presentForText:txt host:host];
}

static void dv_attach(UIView *view) {
    if (!DVEnableLongPress()) return;
    if (!dv_ok(view)) return;
    if (objc_getAssociatedObject(view, kDVTapKey)) return;
    objc_setAssociatedObject(view, kDVTapKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    @try {
        UILongPressGestureRecognizer *g =
            [[UILongPressGestureRecognizer alloc] initWithTarget:view
                                                          action:@selector(dv_lp:)];
        g.minimumPressDuration = 0.5;
        g.numberOfTouchesRequired = 1;
        g.cancelsTouchesInView = NO;
        g.delaysTouchesBegan = NO;
        [view addGestureRecognizer:g];
        NSLog(@"[豆包语音] 挂上 %@", NSStringFromClass([view class]));
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] 挂手势异常 %@", e.reason);
    }
}

@interface UIView (DVReader)
- (void)dv_lp:(UILongPressGestureRecognizer *)g;
@end

@implementation UIView (DVReader)
- (void)dv_lp:(UILongPressGestureRecognizer *)g {
    @try {
        dv_on_long_press(self, g);
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] 长按异常 %@", e.reason);
    }
}
@end

#pragma mark - hooks

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) return;
        dv_attach(self);
    } @catch (NSException *e) {}
}
%end

%hook UITextView
- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) return;
        dv_attach(self);
    } @catch (NSException *e) {}
}
%end

%hook UITextField
- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) return;
        dv_attach(self);
    } @catch (NSException *e) {}
}
%end

%hook MMGrowTextView
- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) return;
        NSLog(@"[豆包语音] 命中 MMGrowTextView");
        dv_attach(self);
    } @catch (NSException *e) {}
}
%end

#pragma mark - 加号面板

static void dv_try_more(id vcObj) {
    if (!vcObj) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if ([vcObj isKindOfClass:[UIViewController class]]) {
            [DVMoreInjector installInto:(UIViewController *)vcObj];
        }
    });
}

%hook WCMoreFunctionViewController
- (void)viewDidLoad {
    %orig;
    dv_try_more(self);
}
%end

%hook WCMoreViewController
- (void)viewDidLoad {
    %orig;
    dv_try_more(self);
}
%end

%hook UIViewController
- (void)viewDidLoad {
    %orig;
    @try {
        NSString *cn = NSStringFromClass([self class]);
        if ([cn containsString:@"DVMore"]) return;
        if ([cn containsString:@"More"] || [cn containsString:@"Function"] ||
            [cn containsString:@"Panel"] || [cn containsString:@"Menu"]) {
            dv_try_more(self);
        }
    } @catch (NSException *e) {}
}
%end

#pragma mark - 启动

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] v1.2.0 已加载 %@ pid=%d longPress=%d",
              [[NSBundle mainBundle] bundleIdentifier], getpid(),
              (int)DVEnableLongPress());
        [DVStore shared];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"豆包语音已就绪"];
        });
    }
}
