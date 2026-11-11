#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#pragma mark - 声明微信私有类

@interface MMMenuItem : NSObject
@end

@interface MMMultiMenuItem : MMMenuItem
@end

@interface MMBaseMultiMenuTableViewCell : UITableViewCell
@end

#pragma mark - 探测 A：微信自己的菜单项类

%hook MMMenuItem

+ (id)alloc {
    NSLog(@"[豆包语音] ★ A1 MMMenuItem alloc");
    return %orig;
}

- (void)setM_title:(id)t {
    NSLog(@"[豆包语音] ★ A2 MMMenuItem setM_title: %@", t);
    %orig;
}

- (void)setMenuItemType:(NSInteger)t {
    NSLog(@"[豆包语音] ★ A3 MMMenuItem setMenuItemType: %ld", (long)t);
    %orig;
}

%end

%hook MMMultiMenuItem

+ (id)alloc {
    NSLog(@"[豆包语音] ★ A4 MMMultiMenuItem alloc");
    return %orig;
}

%end

%hook MMBaseMultiMenuTableViewCell

- (void)setMenuItemType:(NSInteger)t {
    NSLog(@"[豆包语音] ★ A5 MMBaseMultiMenuTableViewCell setMenuItemType: %ld", (long)t);
    %orig;
}

- (void)layoutSubviews {
    NSLog(@"[豆包语音] ★ A6 MMBaseMultiMenuTableViewCell layoutSubviews");
    %orig;
}

%end

#pragma mark - 探测 B：系统 UIContextMenu 路径

%hook UIContextMenuConfiguration

+ (instancetype)configurationWithIdentifier:(id)identifier
                            previewProvider:(id)previewProvider
                             actionProvider:(id (^)(NSArray *))actionProvider {
    NSLog(@"[豆包语音] ★ B1 UIContextMenuConfiguration 被创建");
    return %orig;
}

+ (instancetype)configurationWithIdentifier:(id)id2
                            previewProvider:(id)pp
                                 actionProvider:(id (^)(NSArray *))ap
                          preferredMenuElementOrder:(NSInteger)order {
    NSLog(@"[豆包语音] ★ B2 UIContextMenuConfiguration(带order) 被创建");
    return %orig;
}

%end

%hook UIMenu

+ (instancetype)menuWithTitle:(NSString *)title
                     children:(NSArray *)children {
    NSLog(@"[豆包语音] ★ B3 UIMenu children 数=%lu", (unsigned long)children.count);
    return %orig;
}

+ (instancetype)menuWithTitle:(NSString *)title
                        image:(UIImage *)image
                   identifier:(NSString *)identifier
                      options:(UIMenuOptions)options
                     children:(NSArray *)children {
    NSLog(@"[豆包语音] ★ B4 UIMenu 完整版 children 数=%lu", (unsigned long)children.count);
    return %orig;
}

%end

#pragma mark - 探测 C：旧的 UIMenuController 路径

%hook UIMenuController

- (void)setMenuItems:(NSArray *)items {
    NSLog(@"[豆包语音] ★ C1 UIMenuController setMenuItems %lu 项", (unsigned long)items.count);
    %orig;
}

- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated {
    NSLog(@"[豆包语音] ★ C2 UIMenuController setMenuVisible=%d", visible);
    %orig;
}

%end

#pragma mark - 探测 D：长按手势

%hook UILongPressGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"[豆包语音] ★ D1 长按手势开始，宿主=%@",
          NSStringFromClass([self.view class]));
    %orig;
}

%end

#pragma mark - 探测 E：TableView 的 contextMenu delegate

%hook UITableView

- (UIContextMenuConfiguration *)contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)ip
                                                                    point:(CGPoint)point {
    NSLog(@"[豆包语音] ★ E1 tableView contextMenu 行=%ld", (long)ip.row);
    return %orig;
}

- (BOOL)shouldShowMenuForRowAtIndexPath:(NSIndexPath *)ip {
    NSLog(@"[豆包语音] ★ E2 tableView shouldShowMenu 行=%ld", (long)ip.row);
    return %orig;
}

%end

#pragma mark - 探测 F：微信消息 cell

%hook UITableViewCell

- (void)didMoveToWindow {
    %orig;
    NSString *cn = NSStringFromClass([self class]);
    if ([cn containsString:@"Message"] || [cn containsString:@"Msg"]) {
        NSLog(@"[豆包语音] ★ F1 消息cell %@", cn);
    }
}

%end

#pragma mark - 启动

%ctor {
    @autoreleasepool {
        NSLog(@"[豆包语音] 暴力试探版 pid=%d 已加载", getpid());
        NSLog(@"[豆包语音] 现在请长按一条消息，然后看 ★ 日志");
    }
}
