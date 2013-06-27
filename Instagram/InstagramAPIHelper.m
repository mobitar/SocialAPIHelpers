
#import "InstagramAPIHelper.h"
#import "IGConnect.h"
#import "SocialNetworksKeys.h"

@interface InstagramAPIHelper () <IGSessionDelegate>
@property (nonatomic, copy) SocialBlock completionBlock;
@property (nonatomic, copy) SocialErrorBlock errorBlock;
@end

@implementation InstagramAPIHelper
+ (instancetype)sharedInstance
{
    static InstagramAPIHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self.class new];
        instance.instagram = [[Instagram alloc] initWithClientId:InstagramClientId() delegate:instance];
    });
    
    return instance;
}

- (void)beginSessionAndAllowLoginUI:(BOOL)showLogin completion:(SocialBlock)completionBlock errorBlock:(SocialErrorBlock)errorBlock
{
    self.completionBlock = completionBlock;
    self.errorBlock = errorBlock;
    [self.instagram authorize:@[@"likes", @"comments", @"relationships"]];
}

- (void)clearBlocks
{
    self.completionBlock = nil;
    self.errorBlock = nil;
}

#pragma mark - Instagram Session Delegate

-(void)igDidLogin
{
    if(self.completionBlock)
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(@{@"token" : self.instagram.accessToken});
            [self clearBlocks];
        });
}

-(void)igDidNotLogin:(BOOL)cancelled
{
    if(self.errorBlock)
        dispatch_async(dispatch_get_main_queue(), ^{
            self.errorBlock([NSError new]);
        });

    [self clearBlocks];
}


-(void)igDidLogout
{
    
}

-(void)igSessionInvalidated
{
    
}

- (void)followUserId:(NSString*)userId accessToken:(NSString*)accessToken
{
    [self followUserId:userId withAccessToken:accessToken];
}

- (void)followUserId:(NSString*)userId withAccessToken:(NSString*)accessToken
{
//    NSString *path = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/relationship?access_token=%@", userId, accessToken];
//    NSDictionary *parameters = @{@"action" : @"follow"};
//    [[AppDelegate serverClient] postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(operation.responseString);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(error.description);
//    }];
}

@end
