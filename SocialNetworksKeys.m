#import "SocialNetworksKeys.h"

static NSString *rootKey = @"SocialAPIHelpers";

NSDictionary *rootDictionary()
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:rootKey];
}

NSString *ModeKey()
{
    BOOL isProduction = [[rootDictionary() objectForKey:@"Production"] boolValue];
    return isProduction ? @"Production" : @"Development";
}

NSString *TwitterConsumerKey()
{
    return rootDictionary()[@"Twitter"][ModeKey()][@"consumerKey"];
}

NSString *TwitterConsumerSecret()
{
    return rootDictionary()[@"Twitter"][ModeKey()][@"consumerSecret"];
}

NSString *FacebookAppId()
{
    return rootDictionary()[@"Facebook"][ModeKey()][@"id"];
}

NSString *FacebookDisplayName()
{
    return rootDictionary()[@"Facebook"][ModeKey()][@"name"];
}

NSString *InstagramClientId()
{
    return rootDictionary()[@"Instagram"][ModeKey()][@"id"];
}