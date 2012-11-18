//
//  WeiboKit.h
//  Weibo_sso_sdk
//
//  Created by Reilost on 11/18/12.
//  Copyright (c) 2012 Reilost. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kSinaWeiboSDKErrorDomain           @"SinaWeiboSDKErrorDomain"
#define kSinaWeiboSDKErrorCodeKey          @"SinaWeiboSDKErrorCodeKey"

#define kSinaWeiboSDKAPIDomain             @"https://open.weibo.cn/2/"
#define kSinaWeiboSDKOAuth2APIDomain       @"https://open.weibo.cn/2/oauth2/"
#define kSinaWeiboWebAuthURL               @"https://open.weibo.cn/2/oauth2/authorize"
#define kSinaWeiboWebAccessTokenURL        @"https://open.weibo.cn/2/oauth2/access_token"

#define kSinaWeiboAppAuthURL_iPhone        @"sinaweibosso://login"
#define kSinaWeiboAppAuthURL_iPad          @"sinaweibohdsso://login"
#define kSinaWeiboRedirectURI              @"http://2.saepush.sinaapp.com/callback.php"
#define kSinaWeiboCallBackScheme           @"RLWeiboSdk"
#define kSinaWeiboTokenKeyChainKey         @"accesstoken_%@"
#define kSinaWeiboExpirDateKeyChainKey     @"expirDate_%@"
#define kKeyChainServiceName               @"weibosdksso"
#define kSinaWeiboTokenExpiredNotification @"com.reilost.weibo_token_expired"
#define kSinaWeiboAuthorizeNotification    @"com.reilost.weibo_authorize_notification"
@interface WeiboKit : NSObject{
    
}
@property (nonatomic,strong) NSString *accessToken;
@property (nonatomic,strong) NSString *weiboUserid;

+(void) defaultAppKey:(NSString *)appKey
            appSecret:(NSString *)appSecrect;
+(void) defaultUid:(NSString *)uid;
+ (WeiboKit *) sharedInstanceCheckTokenExpired:(BOOL)check;
+ (WeiboKit *) sharedInstance;

#pragma make init method
-(id)initWith:(NSString *)weiboUserId appKey:(NSString *)appKey
appSecret:(NSString *)appSecrect checkTokenExpired:(BOOL)check;
-(void)getWeiboUserTokenFromKeyChain:(NSString *)weiboUserId checkTokenExpired:(BOOL)check;
#pragma mark authorize method
-(void)authorizeIn:(UIViewController *)vc presentedViewController:(BOOL)presented
           success:(void (^)(NSDictionary *result))success
           failure:(void (^)(NSDictionary *errorInfo))failure;

-(void)logOut;
-(BOOL)isLogin;


-(NSDictionary *)  handleAuthorizeResult:(NSString *)result;

#pragma mark callback method

+(void)handleOpenURL:(NSURL *)url;


@end
