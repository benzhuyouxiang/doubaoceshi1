#import <Foundation/Foundation.h>

@interface DVStore : NSObject
+ (instancetype)shared;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *resourceId;
@property (nonatomic, copy) NSString *speaker;
@property (nonatomic) int sampleRate;
@end

BOOL DVReadBool(NSString *key, BOOL defVal);
BOOL DVEnableLongPress(void);
BOOL DVStreamPlay(void);
