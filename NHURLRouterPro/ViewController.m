//
//  ViewController.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/2.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "ViewController.h"
#import "PBMediator+WebBrowser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGRect bounds = CGRectMake(100, 200, 200, 50);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"call web by url" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(callNativeWebBrowserByURL) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    bounds.origin.y += 100;
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"call web by category" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(callNativeWebBrowserByCategory) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)callNativeWebBrowserByURL {
    
    NSString *url = @"balabala://NHWebBrowser/initWithUrlParams:?url=http://baidu.com&theme=南湖";
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    UIViewController *ctr = [[PBMediator shared] nativeCallWithURL:[NSURL URLWithString:url]];
    [self.navigationController pushViewController:ctr animated:true];
    
}

- (void)callNativeWebBrowserByCategory {
    
    //UIViewController *ctr = [[PBMediator shared] wb_calledByTitle:@"baidu" withUrl:@"http://github.com/iFindTA/"];
    //[self.navigationController pushViewController:ctr animated:true];
    
    NSString *url = @"balabala://NHWebBrowser/initWithUrlParams:";
    NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:@"http://github.com/iFindTA/",@"url",@"iFindTA",@"theme", nil];
    UIViewController *ctr = [[PBMediator shared] nativeCallWithURL:[NSURL URLWithString:url] withParams:aDict];
    [self.navigationController pushViewController:ctr animated:true];
}


@end
