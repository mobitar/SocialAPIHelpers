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
    return rootDictionary()[ModeKey()][@"Twitter"][@"consumerKey"];
}

NSString *TwitterConsumerSecret()
{
    return rootDictionary()[ModeKey()][@"Twitter"][@"consumerSecret"];
}

NSString *FacebookAppId()
{
    return rootDictionary()[ModeKey()][@"Facebook"][@"id"];
}

NSString *FacebookDisplayName()
{
    return rootDictionary()[ModeKey()][@"Facebook"][@"name"];
}

NSString *InstagramClientId()
{
    return rootDictionary()[ModeKey()][@"Instagram"][@"id"];
}