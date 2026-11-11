#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "Prefs/DVStore.h"
#import "UI/DVHUD.h"

#pragma mark - 只查 MM/WC 类

static void dv_scan_method(NSString *selName) {
    @try {
        SEL sel = NSSelectorFromString(selName);
        if (!sel) return;

        int count = objc_getClassList(NULL, 0);
        if (count <= 0) return;
        Class *classes = (Class *)malloc(sizeof(Class) * count);
        if (!classes) return;
        objc_getClassList(classes, count);

        NSLog(@"[豆包语音] ===== 谁有 %@ =====", selName);
        int found = 0;
        for (int i = 0; i < count; i++) {
            @try {
                Class c = classes[i];
                if (!c) continue;
                const char *nm = class_getName(c);
                if (!nm) continue;
                // 只查 MM/WC/CM 开头的微信类
                if (!(nm[0]=='M' && nm[1]=='M') &&
                    !(nm[0]=='W' && nm[1]=='C') &&
                    !(nm[0]=='C' && nm[1]=='M')) continue;

                if (class_respondsToSelector(c, sel)) {
                    NSLog(@"[豆包语音]   %s", nm);
                    found++;
                }
            } @catch (NSException *e) {}
        }
        free(classes);
        if (found == 0) NSLog(@"[豆包语音]   没找到");
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] scan 异常 %@", e.reason);
    }
}

static void dv_dump_class(NSString *name) {
    @try {
        Class c = NSClassFromString(name);
        if (!c) { NSLog(@"[豆包语音] ??? %@ 不存在", name); return; }

        NSString *sup = @"?";
        @try { sup = NSStringFromClass(class_getSuperclass(c)); } @catch (NSException *e) {}
        NSLog(@"[豆包语音] ===== %@ (父类 %@) =====", name, sup);

        unsigned int n = 0;
        Method *ms = NULL;
        @try { ms = class_copyMethodList(c, &n); } @catch (NSException *e) {}
        if (ms) {
            for (unsigned int i = 0; i < n; i++) {
                @try {
                    NSLog(@"[豆包语音]   -%s", sel_getName(method_getName(ms[i])));
                } @catch (NSException *e) {}
            }
            free(ms);
        }

        unsigned int pn = 0;
        objc_property_t *ps = NULL;
        @try { ps = class_copyPropertyList(c, &pn); } @catch (NSException *e) {}
        if (ps) {
            for (unsigned int i = 0; i < pn; i++) {
                @try {
                    NSLog(@"[豆包语音]   @property %s", property_getName(ps[i]));
                } @catch (NSException *e) {}
            }
            free(ps);
        }

        unsigned int ivn = 0;
        Ivar *ivs = NULL;
        @try { ivs = class_copyIvarList(c, &ivn); } @catch (NSException *e) {}
        if (ivs) {
            for (unsigned int i = 0; i < ivn; i++) {
                @try {
                    NSLog(@"[豆包语音]   _%s", ivar_getName(ivs[i]));
                } @catch (NSException *e) {}
            }
            free(ivs);
        }
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] dump %@ 异常 %@", name, e.reason);
    }
}

#pragma mark - 启动

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] 探测版4 pid=%d", getpid());

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            @try {
                dv_dump_class(@"MMMenuItem");
                dv_dump_class(@"MMMultiMenuItem");
                dv_dump_class(@"MMBaseMultiMenuTableViewCell");

                dv_scan_method(@"getExtMenuItems");
                dv_scan_method(@"setArrMenuItems:");
                dv_scan_method(@"setMenuItemType:");
                dv_scan_method(@"updateMoreMenu:");

                NSLog(@"[豆包语音] 探测全部完成");
                [DVHUD show:@"探测完成"];
            } @catch (NSException *e) {
                NSLog(@"[豆包语音] 探测异常 %@", e.reason);
                [DVHUD showError:@"探测异常"];
            }
        });
    }
}
