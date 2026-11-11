#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"

static const void *kDVTapKey = &kDVTapKey;

static NSString *dv_text_of(UIView *view) {
    if (!view) return nil;
    @try {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *lb = (UILabel *)view;
            NSAttributedString *at = lb.attributedText;
            if (at.length) return at.string;
            return lb.text;
        }
    } @catch (NSException *e) {}
    return nil;
}

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

@interface UIView (DVReader)
- (void)dv_lp:(UILongPressGestureRecognizer *)g;
@end

@implementation UIView (DVReader)
- (void)dv_lp:(UILongPressGestureRecognizer *)g {
    NSLog(@"[豆包语音] 长按触发 state=%ld", (long)g.state);
}
@end

static void dv_attach(UIView *view) {
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
    } @catch (NSException *e) {}
}

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) return;
        dv_attach(self);
    } @catch (NSException *e) {}
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] 测试I pid=%d", getpid());
        [DVStore shared];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"I 就绪"];
        });
    }
}
