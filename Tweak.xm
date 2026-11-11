#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"

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

static void dv_scan(UIView *view) {
    if (!dv_ok(view)) return;
    NSLog(@"[豆包语音] 通过 %@ : %@", NSStringFromClass([view class]), dv_text_of(view));
}

%hook UILabel
- (void)didMoveToWindow {
    %orig;
    @try {
        if (!self.window) return;
        dv_scan(self);
    } @catch (NSException *e) {}
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] 测试H pid=%d", getpid());
        [DVStore shared];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"H 就绪"];
        });
    }
}
