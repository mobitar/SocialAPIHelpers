
#import <Foundation/Foundation.h>
#import "SocialAPIHelper.h"

@protocol FBGraphUser;

typedef NS_ENUM(NSInteger, FacebookAudienceType)
{
    FacebookAudienceTypeSelf = 0,
    FacebookAudienceTypeFriends,
    FacebookAudienceTypeEveryone
};

BOOL FacebookAudienceTypeIsRestricted(FacebookAudienceType type);

@interface FacebookAPIHelper : NSObject

+ (instancetype)sharedInstance;

- (void)getAppAudienceType:(void(^)(FacebookAudienceType audienceType, NSError *error))completionBlock;
- (void)openSessionWithBasicInfo:(void(^)( NSError *error))completionBlock;
- (void)requestPublishPermissions:(void(^)( NSError *error))completionBlock;
- (void)getUserInfo:(void(^)(id<FBGraphUser> user, NSError *error))completionBlock;
- (void)openSessionWithBasicInfoThenRequestPublishPermissions:(void(^)(NSError *error))completionBlock;
- (void)openSessionWithBasicInfoThenRequestPublishPermissionsAndGetAudienceType:(void(^)(NSError *error, FacebookAudienceType))completionBlock;

- (NSString*)accessToken;
- (BOOL)handleOpenUrl:(NSURL*)url;
- (void)logout;
@end
