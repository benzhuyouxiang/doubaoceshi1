#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"

#pragma mark - 探测：扫所有含 Menu 的类

static void dv_dump_menu_classes(void) {
    int count = objc_getClassList(NULL, 0);
    if (count <= 0) return;
    Class *classes = (Class *)malloc(sizeof(Class) * count);
    objc_getClassList(classes, count);

    NSMutableArray *hits = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        if ([name containsString:@"Menu"] ||
            [name containsString:@"Callout"] ||
            [name containsString:@"Bar"] ||
            [name containsString:@"Board"]) {
            [hits addObject:name];
        }
    }
    free(classes);

    NSLog(@"[豆包语音] ===== 含 Menu/Bar 的类 %lu 个 =====", (unsigned long)hits.count);
    for (NSString *n in [hits sortedArrayUsingSelector:@selector(compare:)]) {
        NSLog(@"[豆包语音]   %@", n);
    }
}

#pragma mark - 探测：打印 UIMenuController 的 menuItems

static void dv_probe_menuitems(void) {
    UIMenuController *mc = [UIMenuController sharedMenuController];
    NSLog(@"[豆包语音] UIMenuController.menuItems = %@", mc.menuItems);
    NSLog(@"[豆包语音] UIMenuController 可见 = %d", mc.isMenuVisible);
}

#pragma mark - hook UIMenuController：打印每次 setMenuItems

%hook UIMenuController

- (void)setMenuItems:(NSArray *)items {
    NSLog(@"[豆包语音] ★ setMenuItems 被调用，%lu 项: %@",
          (unsigned long)items.count, items);
    %orig;
}

- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated {
    NSLog(@"[豆包语音] ★ setMenuVisible=%d", visible);
    %orig;
}

- (void)update {
    NSLog(@"[豆包语音] ★ UIMenuController update 被调用");
    %orig;
}

%end

#pragma mark - 探测：hook 微信可能用的菜单类

%hook NSObject

+ (void)load {
    %orig;
}

%end

#pragma mark - 启动

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] 探测版 pid=%d 已加载", getpid());
        [DVStore shared];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            dv_dump_menu_classes();
            dv_probe_menuitems();
            [DVHUD show:@"探测版就绪"];
        });
    }
}
