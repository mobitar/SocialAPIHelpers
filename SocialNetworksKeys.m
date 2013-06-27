#import "SocialNetworksKeys.h"

#define PRODUCTION 0

#define PRODUCTION_TWITTER_CONSUMER_KEY @""
#define PRODUCTION_TWITTER_CONSUMER_SECRET @""

#define DEV_TWITTER_CONSUMER_KEY @""
#define DEV_TWITTER_CONSUMER_SECRET @""

#define PRODUCTION_FACEBOOK_APP_ID @""
#define PRODUCTION_FACEBOOK_DISPLAY_NAME @""

#define DEV_FACEBOOK_APP_ID @""
#define DEV_FACEBOOK_DISPLAY_NAME @""

#define PRODUCTION_INSTAGRAM_CLIENT_ID @"testing bra"
#define DEV_INSTAGRAM_CLIENT_ID @""

NSString *TwitterConsumerKey()
{
    return PRODUCTION ? PRODUCTION_TWITTER_CONSUMER_KEY : DEV_TWITTER_CONSUMER_KEY;
}

NSString *TwitterConsumerSecret()
{
    return PRODUCTION ? PRODUCTION_TWITTER_CONSUMER_SECRET : DEV_TWITTER_CONSUMER_SECRET;
}

NSString *FacebookAppId()
{
    return PRODUCTION ? PRODUCTION_FACEBOOK_APP_ID : DEV_FACEBOOK_APP_ID;
}

NSString *FacebookDisplayName()
{
    return PRODUCTION ? PRODUCTION_FACEBOOK_DISPLAY_NAME : DEV_FACEBOOK_DISPLAY_NAME;
}

NSString *InstagramClientId()
{
    return PRODUCTION ? PRODUCTION_INSTAGRAM_CLIENT_ID : DEV_INSTAGRAM_CLIENT_ID;
}