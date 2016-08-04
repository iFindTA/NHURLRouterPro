//
//  PBMediator.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "PBMediator.h"
#import <objc/message.h>

static NSString * const PBScheme        =   @"balabala";
NSString * const PBQuerySelector        =   @"canOpenUrl:";

@interface PBMediator ()

@end

static PBMediator * instance = nil;

@implementation PBMediator

+ (PBMediator *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PBMediator alloc] init];
    });
    return instance;
}

/**
 *  eg. url=[Scheme]://[target]/[selector]?[params].
 */
- (UIViewController *)remoteCallWithURL:(NSURL *)url {
    //TODO:这里可以加入一下安全的机制 譬如在Appdelegate里验证sourceApplication的合法性
    return [self nativeCallWithURL:url];
}

- (UIViewController *)nativeCallWithURLString:(NSString *)urlString {
    return [self nativeCallWithURL:[NSURL URLWithString:urlString]];
}

//parser url's query as a dictionary
- (NSDictionary *)parserQueryString:(nullable NSString *)string {
    if (!string) {
        return nil;
    }
    __block NSMutableDictionary *aDict = [NSMutableDictionary dictionary];
    NSArray *tmp = [string componentsSeparatedByString:@"&"];
    if (!tmp || tmp.count == 0) {
        tmp = [string componentsSeparatedByString:@"|"];
    }
    [tmp enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *keyValue = [obj componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            [aDict setObject:keyValue[1] forKey:keyValue[0]];
        }else{
            NSLog(@"%s-%@-parser error!",__func__,obj);
        }
    }];
    return [aDict copy];
}

- (BOOL)canOpened:(NSString *)aTarget byUrl:(NSURL *)url {
    //询问是否允许提供服务
    SEL selector = NSSelectorFromString(PBQuerySelector);
    Class aClass = NSClassFromString(aTarget);
    BOOL wetherCan = false;
    if ([aClass instancesRespondToSelector:selector]) {
        //objc_msgSend 64位的硬件上crash
        //        id ret = ((id(*)(id, SEL, id))objc_msgSend)(tmpCtr, selector, url);
        //        id ret = [tmpCtr performSelector:selector withObject:url];
        id aInstance = [[aClass alloc] init];
        BOOL (*msgSend)(id, SEL, NSURL *) = (BOOL (*)(id, SEL, NSURL *))objc_msgSend;
        wetherCan = msgSend(aInstance, selector, url);
    }
    return wetherCan;
}

- (PBNotFounder *)generateNotFounder {
    PBNotFounder *notfounder = [[PBNotFounder alloc] init];
    return notfounder;
}

- (UIViewController *)nativeCallWithURL:(NSURL *)url {
    if (![url.scheme isEqualToString:PBScheme]) {
        return [self generateNotFounder];
    }
    NSString *aTarget = url.host;
    NSString *aSelector = url.path;
    aSelector = [aSelector stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *aParams = url.query;
    NSDictionary *params = [self parserQueryString:aParams];
    //return [self nativeCallTarget:aTarget forSelector:aSelector withParams:params];
    //询问是否允许提供服务
    BOOL wetherCan = [self canOpened:aTarget byUrl:url];
    UIViewController *tmpCtr = nil;
    if (wetherCan) {
        tmpCtr = [self nativeCallTarget:aTarget forSelector:aSelector withParams:params];
    }
    return wetherCan?tmpCtr:[self generateNotFounder];
}

- (UIViewController *)nativeCallTarget:(NSString *)target forSelector:(NSString *)selector withParams:(NSDictionary *)params {
    UIViewController *destCtr = nil;
    if (target && selector) {
        NSError *error = nil;
//        id aDester = [target pb_generateInstanceByInitMethod:selector withError:&error,@"http://baidu.com"];
        id aDester = [target pb_generateInstanceByInitMethod:selector withError:&error,params];
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
