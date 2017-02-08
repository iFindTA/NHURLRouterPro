//
//  PBMediator.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "PBMediator.h"
#import <objc/message.h>

NSString * const PBQueryRemoteSelector                      =   @"canOpenedByRemoteUrl:";
NSString * const PBQueryNativeSelector                      =   @"canOpenedByNativeUrl:";

//default max caches
static long long PB_MEDIATOR_CACHE_SIZE                     =   5*1024*1024;
#pragma mark ==PBCache Class ==
@interface PBAutoPurgeCache : NSCache
@end

@implementation PBAutoPurgeCache

- (nonnull instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end

#pragma mark == PBMediator Class ==
@interface PBMediator ()

/**
 the schemes for trust
 */
@property (nonatomic, strong) NSArray *trustSchemes;

/**
 the class's instance caches
 */
@property (nonatomic, readwrite, strong) NSCache <NSString *,id>* classCaches;

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

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (void)setupMaxCacheSize:(long long)size {
    [PBMediator shared].classCaches.totalCostLimit = size;
}

#pragma mark -- getter

- (NSCache <NSString *, id>*)classCaches {
    if (!_classCaches) {
        _classCaches = [[PBAutoPurgeCache alloc] init];
        _classCaches.totalCostLimit = PB_MEDIATOR_CACHE_SIZE;
    }
    return _classCaches;
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
    NSEnumerator *enumerator = [tmp objectEnumerator];
    NSString *key_value = nil;
    while (key_value = [enumerator nextObject] ) {
        NSArray *keyValue = [key_value componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            [aDict setObject:keyValue[1] forKey:keyValue[0]];
        }else{
            NSLog(@"%s-%@-parser error!",__func__,key_value);
        }
    }
    return [aDict copy];
}

#pragma mark -- Query the target wether can be opened!

- (BOOL)wetherTrustScheme:(NSString *)scheme {
    if (scheme.length==0) {
        return false;
    }
    __block BOOL trust = false;
    scheme = scheme.lowercaseString;
    
    NSEnumerator *enumerator = [self.trustSchemes objectEnumerator];
    NSString *tmp_scheme = nil;
    while (tmp_scheme = [enumerator nextObject]) {
        if ([tmp_scheme.lowercaseString isEqualToString:scheme]) {
            trust = true;
            break;
        }
    }
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
    //wether trust the scheme
    if (![self wetherTrustScheme:url.scheme]) {
        return false;
    }
    //wether indecate a target that non-none!
    if (aTarget.length == 0) {
        return false;
    }
    //询问是否允许提供服务
    SEL selector = NSSelectorFromString(remote?PBQueryRemoteSelector:PBQueryNativeSelector);
    Class aClass = NSClassFromString(aTarget);
    BOOL wetherCan = false;
    if (aClass && [aClass instancesRespondToSelector:selector]) {
        //query class instance var from cache first
        id aInstance = [self.classCaches objectForKey:aTarget];
        if (aInstance == nil) {
            //create a new instance for the 'target' class
            aInstance = [[aClass alloc] init];
            //cache the instance
            [self.classCaches setObject:aInstance forKey:aTarget];
        }
        //objc_msgSend 64位的硬件上crash
        //        id ret = ((id(*)(id, SEL, id))objc_msgSend)(tmpCtr, selector, url);
        //        id ret = [tmpCtr performSelector:selector withObject:url];
        BOOL (*msgSend)(id, SEL, NSURL *) = (BOOL (*)(id, SEL, NSURL *))objc_msgSend;
        wetherCan = msgSend(aInstance, selector, url);
    }
    return wetherCan;
}

- (PBNotFounder *)generateNotFounder {
    static PBNotFounder *notfounder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notfounder = [[PBNotFounder alloc] init];
    });
    return notfounder;
}

- (void)cleanClassCaches {
    [self.classCaches removeAllObjects];
    _classCaches = nil;
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

- (UIViewController *)nativeCallWithURL:(NSURL *)url withParams:(NSDictionary * _Nonnull)aDict {
    NSString *aTarget = [url host];
    BOOL canOpend = [self canOpened:aTarget byNativeUrl:url];
    if (!canOpend) {
        return [self generateNotFounder];
    }
    NSString *aSelector = url.path;
    aSelector = [aSelector stringByReplacingOccurrencesOfString:@"/" withString:@""];
    //NSString *aParams = url.query;
    //NSDictionary *params = [self parserQueryString:aParams];
    //return [self nativeCallTarget:aTarget forSelector:aSelector withParams:params];
    UIViewController *tmpCtr = [self nativeCallTarget:aTarget forSelector:aSelector withParams:aDict];
    
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
