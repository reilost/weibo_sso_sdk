//
//  WebViewController.h
//  DoubanAPIEngineDemo
//
//  Created by Lin GUO on 3/26/12.
//  Copyright (c) 2012 douban Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface WebViewController : UIViewController<UIWebViewDelegate>{
       UIActivityIndicatorView *indicatorView;
}

@property (nonatomic,getter = isPresented)BOOL presented;
- (id)initWithRequestURL:(NSURL *)aURL;
-(void)closeWebView;
@end
