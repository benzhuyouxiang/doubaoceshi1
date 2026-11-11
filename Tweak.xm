#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] 测试D 无hook pid=%d", getpid());
        [DVStore shared];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [DVHUD show:@"无hook版就绪"];
        });
    }
}
