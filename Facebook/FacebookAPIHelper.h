
#import <Foundation/Foundation.h>
#import "SocialAPIHelper.h"

@class FBSession;
@interface FacebookAPIHelper : SocialAPIHelper
@property (nonatomic) FBSession *session;
- (BOOL)handleOpenUrl:(NSURL*)url;

typedef NS_ENUM(NSInteger, FacebookAudienceType)
{
    FacebookAudienceTypeSelf = 0,
    FacebookAudienceTypeFriends,
    FacebookAudienceTypeEveryone
};

- (void)checkForAudienceTypeWithCompletionBlock:(void(^)(FacebookAudienceType audienceType))completionBlock errorBlock:(void(^)(NSError *error))errorBlock;
- (void)requestNewPublishPermissions;
@end
