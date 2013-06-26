
#import "SocialAPIHelper.h"
@class Instagram;
@interface InstagramAPIHelper : SocialAPIHelper
@property (nonatomic) Instagram *instagram;
- (void)followUserId:(NSString*)userId accessToken:(NSString*)accessToken;
@end
