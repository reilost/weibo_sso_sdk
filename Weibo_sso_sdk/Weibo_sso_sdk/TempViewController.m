//
//  TempViewController.m
//  Weibo_sso_sdk
//
//  Created by Reilost on 11/18/12.
//  Copyright (c) 2012 Reilost. All rights reserved.
//

#import "TempViewController.h"
#import "WeiboKit.h"
@interface TempViewController ()

@end

@implementation TempViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)loadView{
    [super loadView];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setTitle:@"---"];
    
    self.view.backgroundColor = [UIColor redColor];
    
    [WeiboKit defaultAppKey:@"170339815" appSecret:@"e0e070aa43b85ce63dc966990d61f9d1"];
    WeiboKit *kit = [WeiboKit sharedInstance];
    
    NSString *currentUid = kit.weiboUserid;
    NSLog(@"current uid is %@",currentUid);
    
    [kit logOut];
    [kit authorizeIn:self presentedViewController:YES success:^(NSDictionary *result) {
        NSLog(@"result is %@",result);
        
        [WeiboKit defaultUid:[result objectForKey:@"uid"]];
    } failure:^(NSDictionary *errorInfo) {
        NSLog(@"error info is %@",errorInfo);
    }];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
