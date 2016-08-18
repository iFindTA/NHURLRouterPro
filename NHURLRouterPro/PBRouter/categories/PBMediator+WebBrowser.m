//
//  PBMediator+WebBrowser.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/4.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "PBMediator+WebBrowser.h"

@implementation PBMediator (WebBrowser)

- (UIViewController *)wb_calledByTitle:(NSString *)title withUrl:(NSString *)url {
    
    UIViewController *destCtr = nil;
    
    NSString *aClass = @"NHWebBrowser";
    NSString *aInit = @"initWithUrl:";
    NSError *error = nil;
    BOOL wetherCan = [self canOpened:aClass byNativeUrl:[NSURL URLWithString:url]];
    if (wetherCan) {
        id aDester = [aClass pb_generateInstanceByInitMethod:aInit withError:&error,url];
        if (!error && aDester != nil) {
            if ([aDester isKindOfClass:[UIViewController class]]) {
                destCtr = (UIViewController *)aDester;
            }
        }else{
            NSLog(@"error:%@",error.localizedDescription);
        }
    }
    
    //not found page to display if not found service!
    if (destCtr == nil) {
        PBNotFounder *notfounder = [self generateNotFounder];
        destCtr = notfounder;
    }
    
    return destCtr;
}

@end
