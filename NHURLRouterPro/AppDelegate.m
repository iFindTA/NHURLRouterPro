//
//  AppDelegate.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/2.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "PBMediator.h"

@interface AppDelegate ()

@property (nonatomic, strong) UINavigationController *rootNaviCtr;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //for safe check to setup scheme
    [PBMediator setupForScheme:@"balabala"];
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithFrame:bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    ViewController *Ctr = [[ViewController alloc] init];
    UINavigationController *naviCtr = [[UINavigationController alloc] initWithRootViewController:Ctr];
    self.window.rootViewController = naviCtr;
    self.rootNaviCtr = naviCtr;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    //balabala://NHWebBrowser/initWithUrlParams:?url=http://baidu.com
    NSLog(@"url:%@---opt:%@",url,options);
    if ([url.scheme isEqualToString:@"balabala"]) {
        UIViewController *ctr = [[PBMediator shared] remoteCallWithURL:url];
        [self.rootNaviCtr pushViewController:ctr animated:true];
        return true;
    }
    return false;
}

@end
