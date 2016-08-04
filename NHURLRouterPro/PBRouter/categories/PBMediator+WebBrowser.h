//
//  PBMediator+WebBrowser.h
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/4.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "PBMediator.h"

@interface PBMediator (WebBrowser)

NS_ASSUME_NONNULL_BEGIN

- (UIViewController *)wb_calledByTitle:(nullable NSString *)title withUrl:(NSString *)url;

NS_ASSUME_NONNULL_END

@end
