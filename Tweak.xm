#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"

static void dv_scan(UIView *view) {
    NSLog(@"[豆包语音] 扫到 %@", NSStringFromClass([view class]));
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
        NSLog(@"[豆包语音] 测试F pid=%d", getpid());
        [DVStore shared];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"F 就绪"];
        });
    }
}
