//
//  WeiboKit.m
//  Weibo_sso_sdk
//
//  Created by Reilost on 11/18/12.
//  Copyright (c) 2012 Reilost. All rights reserved.
//

#import "WeiboKit.h"
#import "SFHFKeychainUtils.h"
#import "WebViewController.h"
@implementation WeiboKit{
    NSString *_appKey;
    NSString *_appSecrect;
    NSTimeInterval _expireTimeInterval;
}
+(void) defaultAppKey:(NSString *)appKey
            appSecret:(NSString *)appSecrect{
    [SFHFKeychainUtils storeUsername:@"weibo_sso_sdk_appkey"
                         andPassword:appKey
                      forServiceName:kKeyChainServiceName
                      updateExisting:YES
                               error:nil];
    [SFHFKeychainUtils storeUsername:@"weibo_sso_sdk_appSecrect"
                         andPassword:appSecrect
                      forServiceName:kKeyChainServiceName
                      updateExisting:YES
                               error:nil];
}
+(void) defaultUid:(NSString *)uid{
    if (uid==nil ||[uid length] ==0) {
        return;
    }
    [SFHFKeychainUtils storeUsername:@"weibo_sso_sdk_default_uid"
                         andPassword:uid
                      forServiceName:kKeyChainServiceName
                      updateExisting:YES
                               error:nil];
    [WeiboKit sharedInstance].weiboUserid = uid;
    [[WeiboKit sharedInstance] getWeiboUserTokenFromKeyChain:uid checkTokenExpired:YES];
  
}

+ (WeiboKit *) sharedInstance{
    static WeiboKit *_sharedClient = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedClient = [[WeiboKit alloc] init];
    });
    
    return _sharedClient;
}
+ (WeiboKit *) sharedInstanceCheckTokenExpired:(BOOL)check{
    WeiboKit *kit = [WeiboKit sharedInstance];
    [kit getWeiboUserTokenFromKeyChain:nil checkTokenExpired:check];
    return kit;
}
#pragma make init method
-(void)changeWeiboUserId:(NSString *)uid{
      self.weiboUserid = uid;
}
-(id)init{
    return [self initWith:nil appKey:nil appSecret:nil checkTokenExpired:NO];
}
-(id)initWith:(NSString *)weiboUserId appKey:(NSString *)appKey
    appSecret:(NSString *)appSecrect checkTokenExpired:(BOOL)check{
    self = [super init];
    if (self) {
        
        if (appKey!=nil) {
            _appKey = appKey;
        }else{
            _appKey = [SFHFKeychainUtils getPasswordForUsername:@"weibo_sso_sdk_appkey"
                                                 andServiceName:kKeyChainServiceName
                                                          error:nil];
        }
        
        if (appSecrect!=nil) {
            _appSecrect=appSecrect;
        }else{
            _appSecrect = [SFHFKeychainUtils getPasswordForUsername:@"weibo_sso_sdk_appSecrect"
                                                 andServiceName:kKeyChainServiceName
                                                          error:nil];
        }
        
        if (weiboUserId!=nil) {
            self.weiboUserid = weiboUserId;
            
        }else{
            self.weiboUserid =  [SFHFKeychainUtils getPasswordForUsername:@"weibo_sso_sdk_default_uid"
                                                           andServiceName:kKeyChainServiceName
                                                                    error:nil];
        }
        [self getWeiboUserTokenFromKeyChain:nil
                          checkTokenExpired:check];
    }
    return self;
}

#pragma mark authorize method
-(void)authorizeIn:(UIViewController *)vc presentedViewController:(BOOL)presented
           success:(void (^)(NSDictionary *result))success
           failure:(void (^)(NSDictionary *errorInfo))failure{
    __block NSDictionary *authorizeResult=nil;
    __block  WebViewController *webViewController =nil;
    dispatch_block_t authroizeBlock = ^(){
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [[NSNotificationCenter defaultCenter]
         addObserverForName:kSinaWeiboAuthorizeNotification
         object:nil
         queue:[NSOperationQueue currentQueue]
         usingBlock:^(NSNotification *notification) {
             authorizeResult = notification.object;
             dispatch_semaphore_signal(sema);
         }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        dispatch_release(sema);
        if (webViewController!=nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                               [webViewController closeWebView];
                           });
        }
        
  
        if ([authorizeResult count] >0) {
            if ([authorizeResult objectForKey:@"user_cancelled"]) {
                failure(@{@"error_description":@"user_cancelled"});
            }else if ([authorizeResult objectForKey:@"sso_error_user_cancelled"]) {
                failure(@{@"error_description":@"sso_error_user_cancelled"});
            }else if ([authorizeResult objectForKey:@"sso_error_invalid_params"]){
                failure(@{@"error_description":@"invalid_params"});
            }else if([authorizeResult objectForKey:@"Invalid sso params"]){
                failure(@{@"error_description":@"Invalid sso params"});
            }else if ([authorizeResult objectForKey:@"error_code"]){
                    NSString *error_code = [ authorizeResult objectForKey:@"error_code"];
                    NSString *error = [authorizeResult objectForKey:@"error"];
                    NSString *error_uri = [authorizeResult objectForKey:@"error_uri"];
                    NSString *error_description = [authorizeResult objectForKey:@"error_description"];
                    NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                               error, @"error",
                                               error_uri, @"error_uri",
                                               error_code, @"error_code",
                                               error_description, @"error_description", nil];
                    
                    failure(errorInfo);
            }else{
                success([authorizeResult copy]);
            }
            
        }else{
            failure(@{@"error_description":@"authorize_faild"});
        }
      
    };
    

    if ([self isWeiboAppInstall]) {
        NSDictionary *params = @{@"client_id":_appKey,  @"redirect_uri":kSinaWeiboRedirectURI,
        @"callback_uri":kSinaWeiboCallBackScheme};
        NSString *ssoUrl = [self serializeURL:kSinaWeiboAppAuthURL_iPhone params:params];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ssoUrl]];       
    }else{
        NSDictionary *params = @{@"client_id":_appKey,  @"redirect_uri":kSinaWeiboRedirectURI,
        @"callback_uri":kSinaWeiboCallBackScheme,@"response_type":@"token",
        @"display":@"mobile",@"with_offical_account":@"1"  };
       NSString *oauthUrlString = [self serializeURL:kSinaWeiboWebAuthURL params:params];
        NSURL *oauthUrl = [NSURL URLWithString:oauthUrlString];
        webViewController = [[WebViewController alloc] initWithRequestURL:oauthUrl];

        if (presented) {
            webViewController.presented=YES;
            UINavigationController *nav= [[UINavigationController alloc]
                                          initWithRootViewController:webViewController];
            [vc presentModalViewController:nav animated:YES];
            
        }else{
            [vc.navigationController pushViewController:webViewController animated:YES];
        }
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),authroizeBlock);
 }


-(void)getWeiboUserTokenFromKeyChain:(NSString *)weiboUserId checkTokenExpired:(BOOL)check{
    if (weiboUserId==nil) {
        weiboUserId = self.weiboUserid;
    }
    if (weiboUserId==nil) {
        return;
    }
    NSString *keyChainKey = nil;
    keyChainKey=[NSString stringWithFormat:kSinaWeiboTokenKeyChainKey,weiboUserId];
    //TODO error.
    NSString *token =  [SFHFKeychainUtils getPasswordForUsername:keyChainKey
                                                  andServiceName:kKeyChainServiceName
                                                           error:nil];
    if (token!=nil && [token length] >0) {
        self.accessToken = token;
    }

    NSString *expirDateKey = nil;
    expirDateKey=[NSString stringWithFormat:kSinaWeiboExpirDateKeyChainKey,weiboUserId];
    NSString *expirDateString = [SFHFKeychainUtils getPasswordForUsername:expirDateKey
                                                           andServiceName:kKeyChainServiceName
                                                                    error:nil];
    if (expirDateKey!=nil) {
        _expireTimeInterval = [expirDateString doubleValue];
    }
    
    if (check) {
        BOOL expried= [self isAuthorizeExpired];
        if (expried) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kSinaWeiboTokenExpiredNotification
             object:weiboUserId];
        }
    }
    
}
-(void)logOut{
    [SFHFKeychainUtils deleteItemForUsername:@"weibo_sso_sdk_default_uid"
                              andServiceName:kKeyChainServiceName error:nil];
    
    NSString *keyChainKey = nil;
    keyChainKey=[NSString stringWithFormat:kSinaWeiboTokenKeyChainKey,self.weiboUserid];
    NSString *expirDateKey = nil;
    expirDateKey=[NSString stringWithFormat:kSinaWeiboExpirDateKeyChainKey,self.weiboUserid];

    [SFHFKeychainUtils deleteItemForUsername:keyChainKey
                              andServiceName:kKeyChainServiceName
                                       error:nil];
    [SFHFKeychainUtils deleteItemForUsername:expirDateKey
                              andServiceName:kKeyChainServiceName
                                       error:nil];
    self.weiboUserid=nil;
    self.accessToken = nil;
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* sinaweiboCookies = [cookies cookiesForURL:
                                 [NSURL URLWithString:@"https://open.weibo.cn"]];
    
    for (NSHTTPCookie* cookie in sinaweiboCookies)
    {
        [cookies deleteCookie:cookie];
    }
}

-(BOOL)isLogin{
    return self.weiboUserid!=nil && self.weiboUserid.length >0;
}
#pragma mark callback method

+(void)handleOpenURL:(NSURL *)url{
    NSString *queryString =url.query;
    NSString *fragment = url.fragment;
    NSDictionary *result  = nil;
     WeiboKit *weiboKit =  [[WeiboKit alloc] init];
    if(queryString.length !=0){
        result =[weiboKit handleAuthorizeResult:queryString];
    }else if(fragment.length!=0){
         result =[weiboKit handleAuthorizeResult:fragment];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSinaWeiboAuthorizeNotification
                                                        object:result];
}


#pragma mark private method
-(NSDictionary *) handleAuthorizeResult:(NSString *)result{
    NSDictionary *dict = [self explodeQueryStringToDictionary:result];
    if ([dict count] ==0) {
        return nil;
    }
    NSString *uid=  [dict objectForKey:@"uid"];
    NSString *token = [dict objectForKey:@"access_token"];
    NSString *remind_in = [dict objectForKey:@"remind_in"];
    //TODO refresh token - - wtf反正一般人没有，有了再说
    if ([uid length] ==0 || [token length] ==0 || [remind_in length] ==0) {
        return dict;
    }
    NSString *keyChainKey = nil;
    keyChainKey=[NSString stringWithFormat:kSinaWeiboTokenKeyChainKey,uid];
    NSString *expirDateKey = nil;
    expirDateKey=[NSString stringWithFormat:kSinaWeiboExpirDateKeyChainKey,uid];
    BOOL storeKeyResult = [SFHFKeychainUtils storeUsername:keyChainKey andPassword:token
                                            forServiceName:kKeyChainServiceName
                                            updateExisting:YES
                                                     error:nil];
    BOOL storeRemindResult = [SFHFKeychainUtils storeUsername:expirDateKey
                                                  andPassword:remind_in
                                               forServiceName:kKeyChainServiceName
                                               updateExisting:YES
                                                        error:nil];
    if (storeKeyResult &&storeRemindResult) {
        return dict;
    }
    return nil;
}

-(BOOL) isWeiboAppInstall{
    return NO;
    NSURL *weiboURL = [NSURL URLWithString:kSinaWeiboAppAuthURL_iPhone];
    BOOL install = [[UIApplication sharedApplication] canOpenURL:weiboURL];
    return install;
}


- (BOOL)isAuthorizeExpired
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return now > _expireTimeInterval;
}


- (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params
{
    NSURL* parsedURL = [NSURL URLWithString:baseURL];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator])
    {
        
        NSString* escaped_value = nil;
        escaped_value= (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes
                                                (
                                                 NULL, /* allocator */
                                                 (CFStringRef)[params objectForKey:key],
                                                 NULL, /* charactersToLeaveUnescaped */
                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                 kCFStringEncodingUTF8);
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];
    
    return [NSString stringWithFormat:@"%@%@%@", baseURL, queryPrefix, query];
}

- (NSMutableDictionary *) explodeQueryStringToDictionary:(NSString *) queryString{
    
    NSArray *firstExplode = [queryString componentsSeparatedByString:@"&"];
    NSArray *secondExplode;
    NSInteger count = [firstExplode count];
    NSMutableDictionary* returnDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        secondExplode =
        [(NSString*)[firstExplode objectAtIndex:i] componentsSeparatedByString:@"="];
        if ([secondExplode count] == 2) {
            [returnDictionary setObject:[secondExplode objectAtIndex:1]
                                 forKey:[secondExplode objectAtIndex:0]];
        }
    }
    return returnDictionary;
}



@end
