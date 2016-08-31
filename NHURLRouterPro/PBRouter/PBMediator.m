//
//  PBMediator.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "PBMediator.h"
#import <objc/message.h>

NSString * const PBQueryRemoteSelector        =   @"canOpenedByRemoteUrl:";
NSString * const PBQueryNativeSelector        =   @"canOpenedByNativeUrl:";

@interface PBMediator ()

@property (nonatomic, strong) NSArray *trustSchemes;

@end

static PBMediator * instance = nil;

@implementation PBMediator

+ (void)setupForTrustSchemes:(NSArray *)schemes {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[PBMediator alloc] init];
            instance.trustSchemes = [NSArray arrayWithArray:schemes];
        }
    });
}

+ (PBMediator *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[PBMediator alloc] init];
        }
    });
    return instance;
}

//parser url's query as a dictionary
- (NSDictionary *)parserQueryString:(nullable NSString *)string {
    if (!string) {
        return nil;
    }
    string = [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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

#pragma mark -- Query the target wether can be opened!

- (BOOL)wetherTrustScheme:(NSString *)scheme {
    if (scheme.length==0) {
        return false;
    }
    __block BOOL trust = false;
    scheme = scheme.lowercaseString;
    [self.trustSchemes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.lowercaseString isEqualToString:scheme]) {
            trust = true;
            *stop = true;
        }
    }];
    return trust;
}

- (BOOL)shouldDisplayURL:(NSURL *)url {
    
    if (!url ||url.scheme.length == 0 || url.host.length==0 || url.path.length==0) {
        return false;
    }
    if (![self wetherTrustScheme:url.scheme]) {
        return false;
    }
    return true;
}

- (BOOL)canOpened:(NSString *)aTarget byRemoteUrl:(NSURL *)url {
    return [self canOpened:aTarget byUrl:url isRemmote:true];
}

- (BOOL)canOpened:(NSString *)aTarget byNativeUrl:(NSURL *)url {
    return [self canOpened:aTarget byUrl:url isRemmote:false];
}
- (BOOL)canOpened:(NSString *)aTarget byUrl:(NSURL *)url isRemmote:(BOOL)remote {
    if (![self wetherTrustScheme:url.scheme]) {
        return false;
    }
    //询问是否允许提供服务
    SEL selector = NSSelectorFromString(remote?PBQueryRemoteSelector:PBQueryNativeSelector);
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

/**
 *  eg. url=[Scheme]://[target]/[selector]?[params].
 */
- (UIViewController *)remoteCallWithURL:(NSURL *)url {
    //TODO:这里可以加入一下安全的机制 譬如在Appdelegate里验证sourceApplication的合法性
    NSString *aTarget = [url host];
    BOOL canOpend = [self canOpened:aTarget byRemoteUrl:url];
    if (!canOpend) {
        return [self generateNotFounder];
    }
    NSString *aSelector = url.path;
    aSelector = [aSelector stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *aParams = url.query;
    NSDictionary *params = [self parserQueryString:aParams];
    //return [self nativeCallTarget:aTarget forSelector:aSelector withParams:params];
    UIViewController *tmpCtr = [self nativeCallTarget:aTarget forSelector:aSelector withParams:params];
    
    return (tmpCtr!=nil)?tmpCtr:[self generateNotFounder];
}

- (UIViewController *)nativeCallWithURL:(NSURL *)url {
    
    NSString *aTarget = [url host];
    BOOL canOpend = [self canOpened:aTarget byNativeUrl:url];
    if (!canOpend) {
        return [self generateNotFounder];
    }
    NSString *aSelector = url.path;
    aSelector = [aSelector stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *aParams = url.query;
    NSDictionary *params = [self parserQueryString:aParams];
    //return [self nativeCallTarget:aTarget forSelector:aSelector withParams:params];
    UIViewController *tmpCtr = [self nativeCallTarget:aTarget forSelector:aSelector withParams:params];
    
    return (tmpCtr!=nil)?tmpCtr:[self generateNotFounder];
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
