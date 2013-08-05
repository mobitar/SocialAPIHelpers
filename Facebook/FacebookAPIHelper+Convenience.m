

#import "FacebookAPIHelper+Convenience.h"

@implementation FacebookAPIHelper (Convenience)

- (void)openSessionWithBasicInfo:(void(^)(NSError *error))completionBlock
{
    [self openSessionWithReadPermissions:@[@"basic_info"] completionBlock:completionBlock];
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

- (void)openSessionWithBasicInfoThenRequestPublishPermissions:(void(^)(NSError *error))completionBlock
{
    __weak id weakSelf = self;
    [self openSessionWithBasicInfo:^(NSError *error) {
        __strong id self = weakSelf;
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

@end
