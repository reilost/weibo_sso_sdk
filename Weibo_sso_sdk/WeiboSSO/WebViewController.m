//
//  WebViewController.m
//  DoubanAPIEngineDemo
//
//  Created by Lin GUO on 3/26/12.
//  Copyright (c) 2012 douban Inc. All rights reserved.
//

#import "WebViewController.h"
#import "WeiboKit.h"
@interface WebViewController ()

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSURL *requestURL;

@end


@implementation WebViewController

@synthesize webView = webView_;
@synthesize requestURL = requestURL_;


#pragma mark - View lifecycle

- (id)initWithRequestURL:(NSURL *)aURL {
    self = [super init];
    if (self) {
        self.requestURL = aURL;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
      self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"取消"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(leftBarButtonAction:)];


    webView_ = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView_.scalesPageToFit = YES;
    webView_.delegate = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL_];

    [self.view addSubview:webView_];
    
    indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                     UIActivityIndicatorViewStyleGray];
    indicatorView.autoresizingMask =
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
    | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:indicatorView];
    [webView_ loadRequest:request];

}


- (void)viewDidUnload {
    self.webView = nil;
    self.requestURL = nil;
    [super viewDidUnload];
}

- (void)leftBarButtonAction:(id)btn{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSinaWeiboAuthorizeNotification
                                                        object:@{@"user_cancelled":@"user_cancelled"}];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL *urlObj =  [request URL];
    NSString *url = [urlObj absoluteString];
    if ([url hasPrefix:kSinaWeiboRedirectURI]) {
        [WeiboKit handleOpenURL:urlObj];
        return NO;
    }
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView{
    [self showIndicator];
}
- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
	[self hideIndicator];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self hideIndicator];
}

-(void)closeWebView{
    if (self.isPresented) {
        [self dismissModalViewControllerAnimated:YES];
    }else{
        [self.navigationController popViewControllerAnimated:YES ];
    }
}


#pragma mark - Activity Indicator

- (void)showIndicator
{
    [indicatorView sizeToFit];
    [indicatorView startAnimating];
    indicatorView.center = webView_.center;
}

- (void)hideIndicator
{
    [indicatorView stopAnimating];
}
@end
