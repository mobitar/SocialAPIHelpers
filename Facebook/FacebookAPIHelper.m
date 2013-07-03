
#import "FacebookAPIHelper.h"
#import <FacebookSDK/FacebookSDK.h>
#import <FacebookSDK/FBGraphObject.h>
#import "SocialNetworksKeys.h"

@interface FacebookAPIHelper ()
// single use blocks. these blocks are immediatly nulled after they are used
@property (nonatomic, copy) void(^openBlock)(NSError *error);
@property (nonatomic, copy) void(^permissionsBlock)(NSError *error);
@end

@implementation FacebookAPIHelper

+ (instancetype)sharedInstance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self.class new];
        [instance setSettings];
    });
    return instance;
}

- (void)setSettings
{
    [FBSettings setDefaultAppID:FacebookAppId()];
    [FBSettings setDefaultDisplayName:FacebookDisplayName()];
}

- (BOOL)handleOpenUrl:(NSURL*)url
{
   return [FBSession.activeSession handleOpenURL:url];
}

NSString *NSStringFromFBSessionState(FBSessionState state)
{
    switch (state) {
        case FBSessionStateClosed:
            return @"FBSessionStateClosed";
        case FBSessionStateClosedLoginFailed:
            return @"FBSessionStateClosedLoginFailed";
        case FBSessionStateCreated:
            return @"FBSessionStateCreated";
        case FBSessionStateCreatedOpening:
            return @"FBSessionStateCreatedOpening";
        case FBSessionStateCreatedTokenLoaded:
            return @"FBSessionStateCreatedTokenLoaded";
        case FBSessionStateOpen:
            return @"FBSessionStateOpen";
        case FBSessionStateOpenTokenExtended:
            return @"FBSessionStateOpenTokenExtended";
            
    }
    return @"Not Found";
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error open:(BOOL)open permissions:(BOOL)permissions
{
    if(self.openBlock && open) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.openBlock(error);
            self.openBlock = nil;
        });
    }
    else if(self.permissionsBlock && permissions) {
        self.permissionsBlock(error);
        self.permissionsBlock = nil;
    }
    
    switch (state) {
        case FBSessionStateOpen:
            break;
        case FBSessionStateOpenTokenExtended:
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        
        default:
            break;
    }
    
//    if (error) {
//        [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//    }
}

- (void)openSessionWithBasicInfo:(void(^)(NSError *error))completionBlock
{
    if([[FBSession activeSession] isOpen]) {
        completionBlock(nil);
        return;
    }
    
    self.openBlock = completionBlock;
    
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sessionStateChanged:session state:status error:error open:YES permissions:NO];
        });
    }];
}

static NSString *const publish_actions = @"publish_actions";

- (void)requestPublishPermissions:(void(^)(NSError *error))completionBlock
{
    if([[[FBSession activeSession] permissions] indexOfObject:publish_actions] != NSNotFound) {
        completionBlock(nil);
        return;
    }
    
    self.permissionsBlock = completionBlock;
    
    [FBSession.activeSession requestNewPublishPermissions:@[publish_actions] defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:^(FBSession *session, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sessionStateChanged:session state:session.state error:error open:NO permissions:YES];
        });
    }];
}

- (void)openSessionWithBasicInfoThenRequestPublishPermissions:(void(^)(NSError *error))completionBlock
{
    @weakify(self);
    [self openSessionWithBasicInfo:^(NSError *error) {
        @strongify(self);
        if(error) {
            completionBlock(error);
            return;
        }
        
        [self requestPublishPermissions:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(error);
            });
        }];
    }];
}

- (void)openSessionWithBasicInfoThenRequestPublishPermissionsAndGetAudienceType:(void(^)(NSError *error, FacebookAudienceType))completionBlock
{
    [self openSessionWithBasicInfoThenRequestPublishPermissions:^(NSError *error) {
        if(error) {
            completionBlock(error, 0);
            return;
        }
        
        [self getAppAudienceType:^(FacebookAudienceType audienceType, NSError *error) {
            if(error) {
                completionBlock(error, 0);
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, audienceType);
            });
        }];
    }];
}

- (void)getUserInfo:(void(^)(id<FBGraphUser> user, NSError *error))completionBlock
{
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         completionBlock(user, error);
     }];
}

- (NSString*)accessToken
{
    return [[[FBSession activeSession] accessTokenData] accessToken];
}

- (void)logout
{
    [FBSession.activeSession closeAndClearTokenInformation];
}

#pragma mark - Other

FacebookAudienceType AudienceTypeForValue(NSString *value)
{
    if([value isEqualToString:@"ALL_FRIENDS"])        return FacebookAudienceTypeFriends;
    if([value isEqualToString:@"SELF"])               return FacebookAudienceTypeSelf;
    if([value isEqualToString:@"EVERYONE"])           return FacebookAudienceTypeEveryone;
    if([value isEqualToString:@"FRIENDS_OF_FRIENDS"]) return FacebookAudienceTypeFriends;
    if([value isEqualToString:@"NO_FRIENDS"])         return FacebookAudienceTypeSelf;
    return FacebookAudienceTypeSelf;
}

BOOL FacebookAudienceTypeIsRestricted(FacebookAudienceType type)
{
    return type == FacebookAudienceTypeSelf;
}

- (void)getAppAudienceType:(void(^)(FacebookAudienceType audienceType, NSError *error))completionBlock
{
    if(![[[FBSession activeSession] accessTokenData] accessToken]) {
        completionBlock(0, [NSError new]);
        return;
    }
    
    NSString *query = @"SELECT value FROM privacy_setting WHERE name = 'default_stream_privacy'";
    NSDictionary *queryParam = @{ @"q": query, @"access_token" :  [[[FBSession activeSession] accessTokenData] accessToken]};
    
    [FBRequestConnection startWithGraphPath:@"/fql" parameters:queryParam HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(error) {
            completionBlock(0, error);
            return;
        }
        
        FBGraphObject *object = result;
        id type = [object objectForKey:@"data"][0][@"value"];
        completionBlock(AudienceTypeForValue(type), nil);
    }];
}

@end