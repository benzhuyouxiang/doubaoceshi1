#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"

static void dv_scan_method(NSString *selName) {
    SEL sel = NSSelectorFromString(selName);
    if (!sel) return;

    int count = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * count);
    objc_getClassList(classes, count);

    NSLog(@"[豆包语音] ===== 谁有 %@ =====", selName);
    int found = 0;
    for (int i = 0; i < count; i++) {
        Class c = classes[i];
        if (class_respondsToSelector(c, sel)) {
            NSLog(@"[豆包语音]   %@", NSStringFromClass(c));
            found++;
        }
    }
    free(classes);
    if (found == 0) NSLog(@"[豆包语音]   没有人有这个方法");
}

static void dv_dump_class(NSString *name) {
    Class c = NSClassFromString(name);
    if (!c) { NSLog(@"[豆包语音] ??? %@ 不存在", name); return; }
    NSLog(@"[豆包语音] ===== %@ (父类 %@) =====",
          name, NSStringFromClass(class_getSuperclass(c)));

    unsigned int n = 0;
    Method *ms = class_copyMethodList(c, &n);
    for (unsigned int i = 0; i < n; i++)
        NSLog(@"[豆包语音]   -%s", sel_getName(method_getName(ms[i])));
    free(ms);

    unsigned int pn = 0;
    objc_property_t *ps = class_copyPropertyList(c, &pn);
    for (unsigned int i = 0; i < pn; i++)
        NSLog(@"[豆包语音]   @property %s", property_getName(ps[i]));
    free(ps);
}

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] 探测版3 pid=%d", getpid());
        [DVStore shared];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            dv_scan_method(@"getExtMenuItems");
            dv_scan_method(@"setArrMenuItems:");
            dv_scan_method(@"setMenuItemType:");
            dv_scan_method(@"updateMoreMenu:");
            dv_dump_class(@"MMMenuItem");
            dv_dump_class(@"MMMultiMenuItem");
            dv_dump_class(@"MMBaseMultiMenuTableViewCell");
            [DVHUD show:@"探测完成"];
        });
    }
}
