//
//  NHWebBrowser.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "NHWebBrowser.h"

@interface NHWebBrowser ()<UIWebViewDelegate>

@property (nonatomic, copy) NSString *originUrl;
@property (nonatomic, strong) UIWebView *wapper;

@end

@implementation NHWebBrowser

- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        self.originUrl = [url copy];
    }
    return self;
}

- (instancetype)initWithUrlParams:(NSDictionary *)params {
    self = [super init];
    if (self) {
        NSString *url = [params objectForKey:@"url"];
        self.originUrl = [url copy];
        self.title = [params objectForKey:@"theme"];
    }
    return self;
}

- (BOOL)canOpenedByNativeUrl:(NSURL *)url {
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIWebView *web = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:web];
    self.wapper = web;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.originUrl]];
    [self.wapper loadRequest:request];
}


@end
