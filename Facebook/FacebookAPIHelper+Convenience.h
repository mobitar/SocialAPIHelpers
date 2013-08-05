

#import "FacebookAPIHelper.h"

@interface FacebookAPIHelper (Convenience)

- (void)openSessionWithBasicInfo:(void(^)( NSError *error))completionBlock;
- (void)openSessionWithBasicInfoThenRequestPublishPermissions:(void(^)(NSError *error))completionBlock;
- (void)openSessionWithBasicInfoThenRequestPublishPermissionsAndGetAudienceType:(void(^)(NSError *error, FacebookAudienceType))completionBlock;

@end
