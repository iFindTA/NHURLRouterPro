//
//  PBMediator.h
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "PBRunner.h"
#import "PBNotFounder.h"

NS_ASSUME_NONNULL_BEGIN

//中间人组件 所有模块之间的耦合引用由其解决
//不同的业务组件可以通过分类扩展实现业务逻辑
@interface PBMediator : NSObject

/**
 *  @brief global config for mediator
 *
 *  @param schemes the safely schemes to trust
 */
+ (void)setupForTrustSchemes:(NSArray *)schemes;

/**
 *  @brief static class method for instance
 *
 *  @return the instance
 */
+ (PBMediator *)shared;

/**
 set max cache size for memory

 @param size :the size, default was 5M
 */
+ (void)setupMaxCacheSize:(long long)size;

/**
 *  @brief wether should show new page for url, such as just open app for url
 *
 *  @param url the url
 *
 *  @return result
 */
- (BOOL)shouldDisplayURL:(NSURL *)url;

/**
 *  @brief called by remote's app or APNS
 *
 *  @param url eg.[scheme]://[target]/[selector]?[params].
 *  @attention:[scheme]:is this app's unique scheme.
 *  @attention:[target]:is a class's name for dest to call.
 *  @attention:[selector]:is a initialized method for the [target].
 *
 *  @attention!!!:the dest component's init method must support Dictionary params!!!
 *  such as:    'initWithParams:(NSDictionary * _Nullable)aDict' and 
 *  it must be implemented by category when params contains non-basic type!!!
 *
 *  @return the component for destCall otherwise a notfound page.
 */
- (UIViewController *)remoteCallWithURL:(NSURL *)url;

/**
 *  @brief called by native
 *
 *  @param url eg.[scheme]://[target]/[selector]?[params].
 *
 *  @attention!!!:the dest component's init mthod must support Dictionary params!!!
 *  such as:    'initWithParams:(NSDictionary * _Nullable)aDict' and
 *  it must be implemented by category when params contains non-basic type!!!
 *
 *  @see    remoteCallWithURL:
 *
 *  @return the component for destCall otherwise a notfound page.
 */
- (UIViewController *)nativeCallWithURL:(NSURL *)url;

/**
 @brief called by native,]

 @param url eg.[scheme]://[target]/[selector],
 @param aDict params
 *
 *  @attention!!!:the url must NOT contain params!!!, params contain in aDict!
 *                  if should do this please use:
 *                  nativeCallWithURL: instead!
 *
 @return the component for destCall otherwise a notfound page.
 */
- (UIViewController *)nativeCallWithURL:(NSURL *)url withParams:(NSDictionary * _Nonnull)aDict;

/**
 *  @brief wether can open url
 *
 *  @param aTarget the dest target to be called
 *  @param url     the info url
 *
 *  @return result
 */
- (BOOL)canOpened:(NSString *)aTarget byRemoteUrl:(NSURL *)url;
- (BOOL)canOpened:(NSString *)aTarget byNativeUrl:(NSURL *)url;

/**
 *  @brief generate an error page
 *
 *  @return the page
 */
- (PBNotFounder *)generateNotFounder;

/**
 clean the class caches that in memory
 */
- (void)cleanClassCaches;

NS_ASSUME_NONNULL_END

@end
