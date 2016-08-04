# NHURLRouterPro
#### iOS application各个业务组件的相互调用、引用的解耦问题，使用到了中间人＋URL Router的方式
#### Usage:(processing->Build Setting->Enable Strict Checking of objc_msgSend Calls == False)!!!

```
	pod 'PBMediator'
```

##### 使用前安全设置Scheme
```Objective-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //for safe check to setup scheme
    [PBMediator setupForScheme:@"balabala"];
    
    ...
    return YES;
}
```

##### 应用远程调用
```Objective-C
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
```
##### 应用内部调用(两种方式：初始化字典传值＋分类实现)
1－初始化字典传值方式
```Objective-C
- (void)callNativeWebBrowserByURL {
    
    NSString *url = @"balabala://NHWebBrowser/initWithUrlParams:?url=http://baidu.com";
    UIViewController *ctr = [[PBMediator shared] nativeCallWithURL:[NSURL URLWithString:url]];
    [self.navigationController pushViewController:ctr animated:true];
    
}
```
2－分类实现方式
```Objective-C
- (void)callNativeWebBrowserByCategory {
    
    UIViewController *ctr = [[PBMediator shared] wb_calledByTitle:@"baidu" withUrl:@"http://github.com/iFindTA/"];
    [self.navigationController pushViewController:ctr animated:true];
}
```

###### 参考
[路由跳转的思考](http://awhisper.github.io/2016/06/12/%E8%B7%AF%E7%94%B1%E8%B7%B3%E8%BD%AC%E7%9A%84%E6%80%9D%E8%80%83/)
[iOS 组件化方案探索](http://wereadteam.github.io/2016/03/19/iOS-Component/)