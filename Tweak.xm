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
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] text异常 %@", e.reason);
    }
    return nil;
}

static void dv_scan(UIView *view) {
    NSString *t = dv_text_of(view);
    if (t.length > 0) {
        NSLog(@"[豆包语音] %@ 文字: %@", NSStringFromClass([view class]), t);
    }
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
        NSLog(@"[豆包语音] 测试G pid=%d", getpid());
        [DVStore shared];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"G 就绪"];
        });
    }
}
