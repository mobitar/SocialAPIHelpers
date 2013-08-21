
#import <Foundation/Foundation.h>
#import <FacebookSDK/FBGraphObject.h>
#import <FacebookSDK/FBGraphUser.h>

typedef NS_ENUM(NSInteger, FacebookAudienceType)
{
    FacebookAudienceTypeSelf = 0,
    FacebookAudienceTypeFriends,
    FacebookAudienceTypeEveryone
};

BOOL FacebookAudienceTypeIsRestricted(FacebookAudienceType type);

@interface FacebookAPIHelper : NSObject

+ (instancetype)sharedInstance;

- (void)openSessionWithBasicInfo:(void(^)( NSError *error))completionBlock;
- (void)requestPublishPermissions:(void(^)( NSError *error))completionBlock;
- (void)getUserInfo:(void(^)(id<FBGraphUser> user, NSError *error))completionBlock;
- (void)openSessionWithBasicInfoThenRequestPublishPermissions:(void(^)(NSError *error))completionBlock;
- (void)openSessionWithBasicInfoThenRequestPublishPermissionsAndGetAudienceType:(void(^)(NSError *error, FacebookAudienceType))completionBlock;

- (void)getFriends:(void(^)(NSArray *friends, NSError *error))completionBlock;
- (void)getAppAudienceType:(void(^)(FacebookAudienceType audienceType, NSError *error))completionBlock;
- (void)showAppRequestDialogueWithMessage:(NSString*)message toUserId:(NSString*)userId;

- (NSString*)accessToken;
- (BOOL)handleOpenUrl:(NSURL*)url;
- (void)handleDidBecomeActive;
- (void)logout;
@end
