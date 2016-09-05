//
//  PBNotFounder.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "PBNotFounder.h"

@interface PBNotFounder ()

@property (nonatomic, assign) BOOL isModalPresented;

@end

@implementation PBNotFounder

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Not Found!";
    
    UILabel *label = [[UILabel alloc] initWithFrame:self.view.bounds];
    label.backgroundColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:15];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = @"抱歉，您访问的服务没有找到！";
    [self.view addSubview:label];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController != nil) {
        self.isModalPresented = self.navigationController.isBeingPresented;
    }else{
        self.isModalPresented = self.isBeingPresented;
    }
    [self fixedBackNavigationItem];
}

- (void)fixedBackNavigationItem {
    UIBarButtonItem *barSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    barSpacer.width = -16;
    NSString *title = self.isModalPresented?@"取消":@"返回";
    CGRect bounds = CGRectMake(0, 0, 50, 31);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    btn.exclusiveTouch = true;
    btn.titleLabel.font = [UIFont systemFontOfSize:13];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backEvent) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backBarItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItems = @[barSpacer, backBarItem];
}

- (void)backEvent {
    if (self.isModalPresented) {
        [self dismissViewControllerAnimated:true completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:true];
    }
}

@end
