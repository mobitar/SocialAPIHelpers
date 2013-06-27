
#import "FacebookAPIHelper.h"
#import <FacebookSDK/FacebookSDK.h>
#import <FacebookSDK/FBGraphObject.h>
#import "SocialNetworksKeys.h"

@interface FacebookAPIHelper ()
@property (nonatomic, copy) SocialBlock completionBlock;
@property (nonatomic, copy) SocialErrorBlock failBlock;
@end

@implementation FacebookAPIHelper
{
    BOOL isGettingWritePermissions;
}

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
   return [self.session handleOpenURL:url];
}

- (BOOL)shouldRequestPublishActions
{
    return [FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound;
}

- (void)requestForMe
{
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         if (!error) {
             self.completionBlock(@{@"token" : self.session.accessTokenData.accessToken, @"name" : user.name, @"id" : user.id});
         } else {
             NSLog(@"Me request:%@", error.description);
         }
     }];
}

- (void)openSession
{
    if([[FBSession activeSession] isOpen]) {
        if([self shouldRequestPublishActions]) {
            [self requestPermissionAndPost];
        } else {
            [self requestForMe];
        }
    } else {
        [self.session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            [FBSession setActiveSession:session];
            if(!error) {
                if ([self shouldRequestPublishActions])
                    [self requestPermissionAndPost];
                else [self requestForMe];
            }
            else {
                [self failWithError:error];
            }
        }];
    }
}

- (void)failWithError:(NSError*)error
{
    self.session = nil;
    [FBSession setActiveSession:nil];
    self.failBlock(error);
}

NSArray *Permissions()
{
    return @[@"publish_actions"];
}

- (void)requestNewPublishPermissions
{
    [FBSession.activeSession requestNewPublishPermissions:Permissions() defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:^(FBSession *session, NSError *error) {
        if(error)
            NSLog(@"Error:%@", (error.description));
    }];
}

- (void)requestPermissionAndPost
{
    if([[FBSession activeSession] isOpen] == NO) {
        [self requestForMe];
        return;
    }
    
    [FBSession.activeSession requestNewPublishPermissions:Permissions() defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:^(FBSession *session, NSError *error) {
        if (!error) {
            [self requestForMe];
        } else {
            [self failWithError:error];
        }
    }];
}

- (void)beginSessionAndAllowLoginUI:(BOOL)showLogin completion:(SocialBlock)completionBlock errorBlock:(SocialErrorBlock)errorBlock
{
    [FBSession setActiveSession:nil];
    self.session = [[FBSession alloc] initWithAppID:FacebookAppId() permissions:@[@"basic_info"] defaultAudience:FBSessionDefaultAudienceEveryone urlSchemeSuffix:nil tokenCacheStrategy:nil];
    [self setSettings];
    
    self.completionBlock = completionBlock;
    self.failBlock = errorBlock;
    
    [self openSession];
}

#pragma mark - Other

FacebookAudienceType AudienceTypeForValue(NSString *value) {
    if([value isEqualToString:@"ALL_FRIENDS"])
        return FacebookAudienceTypeFriends;
    if([value isEqualToString:@"SELF"])
        return FacebookAudienceTypeSelf;
    if([value isEqualToString:@"EVERYONE"])
        return FacebookAudienceTypeEveryone;
    if([value isEqualToString:@"FRIENDS_OF_FRIENDS"])
        return FacebookAudienceTypeFriends;
    if([value isEqualToString:@"NO_FRIENDS"])
        return FacebookAudienceTypeSelf;
    
    return FacebookAudienceTypeSelf;
}

- (void)checkForAudienceTypeWithCompletionBlock:(void(^)(FacebookAudienceType audienceType))completionBlock errorBlock:(void(^)(NSError *error))errorBlock
{
    if(![[[FBSession activeSession] accessTokenData] accessToken]) {
        if(errorBlock)
            errorBlock(nil);
        return;
    }
    
    NSString *query = @"SELECT value FROM privacy_setting WHERE name = 'default_stream_privacy'";
    NSDictionary *queryParam = @{ @"q": query, @"access_token" :  [[[FBSession activeSession] accessTokenData] accessToken]};
    
    [FBRequestConnection startWithGraphPath:@"/fql" parameters:queryParam HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            if(errorBlock)
                errorBlock(error);
        } else {
            FBGraphObject *object = result;
            id type = [object objectForKey:@"data"][0][@"value"];
            if(completionBlock)
                completionBlock(AudienceTypeForValue(type));
        }
    }];
}

@end