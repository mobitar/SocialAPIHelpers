
#import <Foundation/Foundation.h>

typedef void (^SocialBlock)(NSDictionary* dictionary);
typedef void (^SocialErrorBlock)(NSError *error);

@interface SocialAPIHelper : NSObject
+ (instancetype)sharedInstance;
- (void)beginSessionAndAllowLoginUI:(BOOL)showLogin completion:(SocialBlock)completionBlock errorBlock:(SocialErrorBlock)errorBlock;
@end
