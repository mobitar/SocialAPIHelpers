
#import <Foundation/Foundation.h>
@class ACAccount;
@interface TwitterAPIHelper : NSObject
@property (nonatomic) UIViewController *externalAuthenticationParentController;

+ (instancetype)sharedInstance;

typedef void(^TwitterAuthenticateHandler)(ACAccount *account, NSError *error);
- (void)authenticate:(TwitterAuthenticateHandler)completionHandler;

typedef void(^TwitterReverseOAuthHandler)(NSString *token, NSString *secret, NSError *error);
- (void)performReverseOAuthForAccount:(ACAccount*)account completion:(TwitterReverseOAuthHandler)completionHandler;

- (void)authenticateAndPerformReverseOAuth:(TwitterReverseOAuthHandler)completionHandler;
@end
