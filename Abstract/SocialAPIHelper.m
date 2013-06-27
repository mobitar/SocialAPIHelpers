
#import "SocialAPIHelper.h"

@implementation SocialAPIHelper

+ (instancetype)sharedInstance
{
    return nil;
}

- (void)beginSessionAndAllowLoginUI:(BOOL)showLogin completion:(SocialBlock)completionBlock errorBlock:(SocialErrorBlock)errorBlock
{
    // must override
    @throw [NSException new];
}
@end
