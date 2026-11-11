#import <Foundation/Foundation.h>
@interface DVTextChunker : NSObject
+ (NSArray *)split:(NSString *)text maxLength:(NSUInteger)max;
@end
