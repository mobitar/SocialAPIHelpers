
#import "TwitterAPIHelper.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "TWAPIManager.h"
#import "MBFlatAlertView.h"

@interface TwitterAPIHelper () <UIActionSheetDelegate>
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, copy) SocialBlock completionBlock;
@property (nonatomic, copy) SocialErrorBlock errorBlock;
@end

@implementation TwitterAPIHelper {
    NSArray *_accounts;
}

+ (instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self.class new];
    });
    
    return instance;
}

- (void)beginSessionAndAllowLoginUI:(BOOL)showLogin completion:(SocialBlock)completionBlock errorBlock:(SocialErrorBlock)errorBlock {
    self.apiManager = [TWAPIManager new];
    self.completionBlock = completionBlock;
    self.errorBlock = errorBlock;
    
    [self obtainAccessToAccounts];
}

- (void)obtainAccessToAccounts {
    self.accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [self showActionSheet];
            } else {
                [[MBFlatAlertView alertWithTitle:@"Access denied" detailText:@"We were unable to access your Twitter accounts. Please go into your device settings and give Freebie access to Twitter." cancelTitle:@"Ok" cancelBlock:nil] addToDisplayQueue];
                self.errorBlock(nil);
            }
        });
    }];
}

- (void)showActionSheet
{
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:accountType];
    
    if(twitterAccounts.count == 0) {
        [[MBFlatAlertView alertWithTitle:@"No accounts" detailText:@"You don't have any Twitter accounts linked to your device. Please go into your device settings and add a Twitter account." cancelTitle:@"Ok" cancelBlock:nil] addToDisplayQueue];
        self.errorBlock(nil);
        return;
    }
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Choose an Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (ACAccount *acct in twitterAccounts) {
        [sheet addButtonWithTitle:acct.username];
    }
    
    _accounts = [twitterAccounts copy];
    
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    [sheet showInView:[[[UIApplication sharedApplication] windows] lastObject]];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [_apiManager performReverseAuthForAccount:_accounts[buttonIndex] withHandler:^(NSData *responseData, NSError *error) {
            if (responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                    NSLog(@"Twitter Auth Response str:%@", responseStr);
                    NSArray *parts = [responseStr componentsSeparatedByString:@"&"];
                    if(parts.count < 2) {
                        self.errorBlock(error);
                        return;
                    }
                    NSString *token = [parts[0] substringFromIndex:12];
                    NSString *secret = [parts[1] substringFromIndex:19];
                    ACAccount *account = _accounts[buttonIndex];
                    self.completionBlock(@{@"token" : token, @"secret" : secret, @"name" : account.username});
                });
            }
            else {
                NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
                self.errorBlock(error);
            }
        }];
    } else {
        self.errorBlock(nil);
    }
}

@end