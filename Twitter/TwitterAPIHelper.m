
#import "TwitterAPIHelper.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "TWAPIManager.h"
#import "MBFlatAlertView.h"
#import "SocialNetworksKeys.h"

#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"

@interface TwitterAPIHelper () <UIActionSheetDelegate, SA_OAuthTwitterControllerDelegate>
@property (nonatomic, copy) TwitterAuthenticateHandler authenticationHandler;
@property (nonatomic, copy) TwitterReverseOAuthHandler reverseOAuthHandler;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic) NSArray *accounts;

@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic) SA_OAuthTwitterEngine *twitterEngine;
@end

@implementation TwitterAPIHelper

+ (instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self.class new];
    });
    
    return instance;
}

- (ACAccountStore*)accountStore
{
    if(!_accountStore) {
        _accountStore = [ACAccountStore new];
    }
    return _accountStore;
}

- (NSArray*)accounts
{
    if(!_accounts) {
        ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        _accounts = [self.accountStore accountsWithAccountType:accountType];
    }
    return _accounts;
}

- (void)authenticate:(TwitterAuthenticateHandler)completionHandler
{
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!granted) {
                completionHandler(nil, [NSError new]);
                return;
            }
            
            self.authenticationHandler = completionHandler;
            
            NSArray *twitterAccounts = [self accounts];
            if(twitterAccounts.count > 0) {
                [self showActionSheetForTwitterAccounts:twitterAccounts];
            } else {
                completionHandler(nil, nil);
            }
        });
    }];
}

- (void)authenticateAndPerformReverseOAuth:(TwitterReverseOAuthHandler)completionHandler
{
    [self authenticate:^(ACAccount *account, NSError *error) {
        if(error || !account) {
            self.reverseOAuthHandler = completionHandler;
            [self beginExternalAuthentication];
            return;
        }
        
        [self performReverseOAuthForAccount:account completion:^(NSString *token, NSString *secret, NSError *error) {
            completionHandler(token, secret, error);
        }];
    }];
}

- (void)showActionSheetForTwitterAccounts:(NSArray*)twitterAccounts
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (ACAccount *acct in twitterAccounts) {
        [sheet addButtonWithTitle:acct.username];
    }
    
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    [sheet showInView:[[[UIApplication sharedApplication] windows] lastObject]];
}

- (TWAPIManager*)apiManager
{
    if(!_apiManager) {
        _apiManager = [[TWAPIManager alloc] init];
    }
    return _apiManager;
}

NSString *TokenFromOAuthResponseString(NSString *string)
{
    NSArray *parts = [string componentsSeparatedByString:@"&"];
    NSString *token = [parts[0] substringFromIndex:12];
    MBLog(token);
    return token;
}

NSString *SecretFromOAuthResponseString(NSString *string)
{
    NSArray *parts = [string componentsSeparatedByString:@"&"];
    NSString *secret = [parts[1] substringFromIndex:19];
    MBLog(secret);
    return secret;
}

- (void)performReverseOAuthForAccount:(ACAccount*)account completion:(TwitterReverseOAuthHandler)completionHandler
{
    [self.apiManager performReverseAuthForAccount:account withHandler:^(NSData *responseData, NSError *error) {
        if (responseData) {
            NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSArray *parts = [responseStr componentsSeparatedByString:@"&"];
            
            if(parts.count < 2) {
                completionHandler(nil, nil, [NSError new]);
                return;
            }

            completionHandler(TokenFromOAuthResponseString(responseStr), SecretFromOAuthResponseString(responseStr), nil);
        }
        else {
            NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
            completionHandler(nil, nil, error);
        }
    }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;

    ACAccount *account = self.accounts[buttonIndex];
    self.authenticationHandler(account, nil);
    self.authenticationHandler = nil;
}

#pragma mark - External Authentication

- (SA_OAuthTwitterEngine*)twitterEngine
{
    if(!_twitterEngine) {
        _twitterEngine = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
        _twitterEngine.consumerKey = TwitterConsumerKey();
        _twitterEngine.consumerSecret = TwitterConsumerSecret();
    }
    return _twitterEngine;
}

- (void)beginExternalAuthentication
{
    UIViewController *controller = [SA_OAuthTwitterController
                                    controllerToEnterCredentialsWithTwitterEngine:self.twitterEngine
                                    delegate:self];
    
    if(!controller) {
        self.reverseOAuthHandler([self cachedToken], [self cachedSecret], nil);
        self.reverseOAuthHandler = nil;
        return;
    }
    
    assert(_externalAuthenticationParentController);
    [_externalAuthenticationParentController presentViewController:controller animated:YES completion:nil];
}



- (NSString*)cachedToken
{
    NSString *string = [[NSUserDefaults standardUserDefaults] objectForKey:@"authData"];
    return TokenFromOAuthResponseString(string);
}

- (NSString*)cachedSecret
{
    NSString *string = [[NSUserDefaults standardUserDefaults] objectForKey:@"authData"];
    return SecretFromOAuthResponseString(string);
}

#pragma mark SA_OAuthTwitterEngineDelegate

- (void)callReverseOAuthBlockWithToken:(NSString*)token secret:(NSString*)secret error:(NSError*)error
{
    self.reverseOAuthHandler(token, secret, error);
    self.reverseOAuthHandler = nil;
}

- (void)storeCachedTwitterOAuthData:(NSString*)data forUsername:(NSString*)username
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:data forKey:@"authData"];
	[defaults synchronize];
    
    [self callReverseOAuthBlockWithToken:[self cachedToken] secret:[self cachedSecret] error:nil];
}

- (NSString *)cachedTwitterOAuthDataForUsername:(NSString *)username
{
	return [[NSUserDefaults standardUserDefaults] objectForKey: @"authData"];
}

#pragma mark SA_OAuthTwitterControllerDelegate

- (void) OAuthTwitterController: (SA_OAuthTwitterController *) controller authenticatedWithUsername:(NSString *) username
{
	NSLog(@"Authenicated for %@", username);
}

- (void) OAuthTwitterControllerFailed: (SA_OAuthTwitterController *) controller
{
	NSLog(@"Authentication Failed!");
    [self callReverseOAuthBlockWithToken:nil secret:nil error:[NSError new]];
}

- (void) OAuthTwitterControllerCanceled: (SA_OAuthTwitterController *) controller
{
	NSLog(@"Authentication Canceled.");
    [self callReverseOAuthBlockWithToken:nil secret:nil error:[NSError new]];
}

#pragma mark TwitterEngineDelegate

- (void) requestSucceeded: (NSString *) requestIdentifier
{
	NSLog(@"Request %@ succeeded", requestIdentifier);
}

- (void) requestFailed: (NSString *) requestIdentifier withError: (NSError *) error
{
	NSLog(@"Request %@ failed with error: %@", requestIdentifier, error);
    [self callReverseOAuthBlockWithToken:nil secret:nil error:[NSError new]];
}


@end