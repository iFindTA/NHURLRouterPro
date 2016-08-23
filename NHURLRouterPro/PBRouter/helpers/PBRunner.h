//
//  PBRunner.h
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PBRunner : NSObject

@end

@interface NSString (PBRunner)

/**
 *  @brief instance's init method in runtime
 *
 *  @param selString the initialized method
 *  @param error     wether there is an error
 *
 *  @return the instance of self's class
 */
- (id)pb_generateInstanceByInitMethod:(NSString *)selString withError:(NSError * __autoreleasing *)error,...;

@end

@interface NSObject (PBRunner)

- (id)pb_instanceCallMethod:(NSString *)selString withError:(NSError * __autoreleasing *)error,...;

@end

NS_ASSUME_NONNULL_END