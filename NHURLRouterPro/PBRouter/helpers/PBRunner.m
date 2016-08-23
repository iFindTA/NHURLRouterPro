//
//  PBRunner.m
//  NHURLRouterPro
//
//  Created by hu jiaju on 16/8/3.
//  Copyright © 2016年 Nanhu. All rights reserved.
//

#import "PBRunner.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif

@implementation PBRunner

@end

@interface pb_pointer : NSObject

@property (nonatomic) void *pointer;

@end

@implementation pb_pointer

@end

@interface pb_nilObject : NSObject

@end

@implementation pb_nilObject

@end

#pragma mark -- static method --

static NSLock *_pbMethodSignatureLock;
static NSMutableDictionary *_pbMethodSignatureCache;
static pb_nilObject *pbnilPointer = nil;

static void pb_generateError(NSString *errorInfo, NSError **error){
    if (error) {
        *error = [NSError errorWithDomain:errorInfo code:0 userInfo:nil];
    }
}

static NSString *pb_extractStructName(NSString *typeEncodeString){
    
    NSArray *array = [typeEncodeString componentsSeparatedByString:@"="];
    NSString *typeString = array[0];
    __block int firstVaildIndex = 0;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        char c = [typeEncodeString characterAtIndex:idx];
        if (c=='{'||c=='_') {
            firstVaildIndex++;
        }else{
            *stop = YES;
        }
    }];
    return [typeString substringFromIndex:firstVaildIndex];
}

static NSString *pb_selectorName(SEL selector){
    const char *selNameCstr = sel_getName(selector);
    NSString *selName = [[NSString alloc]initWithUTF8String:selNameCstr];
    return selName;
}

static NSMethodSignature *pb_getMethodSignature(Class cls, SEL selector){
    
    [_pbMethodSignatureLock lock];
    
    if (!_pbMethodSignatureCache) {
        _pbMethodSignatureCache = [[NSMutableDictionary alloc]init];
    }
    if (!_pbMethodSignatureCache[cls]) {
        _pbMethodSignatureCache[(id<NSCopying>)cls] =[[NSMutableDictionary alloc]init];
    }
    NSString *selName = pb_selectorName(selector);
    NSMethodSignature *methodSignature = _pbMethodSignatureCache[cls][selName];
    if (!methodSignature) {
        methodSignature = [cls instanceMethodSignatureForSelector:selector];
        if (methodSignature) {
            _pbMethodSignatureCache[cls][selName] = methodSignature;
        }else
        {
            methodSignature = [cls methodSignatureForSelector:selector];
            if (methodSignature) {
                _pbMethodSignatureCache[cls][selName] = methodSignature;
            }
        }
    }
    [_pbMethodSignatureLock unlock];
    return methodSignature;
}

static NSArray *pb_targetBoxingArguments(va_list argList, Class cls, SEL selector, NSError *__autoreleasing *error){
    
    NSMethodSignature *methodSignature = pb_getMethodSignature(cls, selector);
    NSString *selName = pb_selectorName(selector);
    
    if (!methodSignature) {
        NSString* errorStr = [NSString stringWithFormat:@"unrecognized selector (%@)", selName];
        pb_generateError(errorStr,error);
        return nil;
    }
    NSMutableArray *argumentsBoxingArray = [[NSMutableArray alloc]init];
    
    for (int i = 2; i < [methodSignature numberOfArguments]; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        switch (argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
                
#define pb_BOXING_ARG_CASE(_typeString, _type)\
case _typeString: {\
_type value = va_arg(argList, _type);\
[argumentsBoxingArray addObject:@(value)];\
break; \
}\

                pb_BOXING_ARG_CASE('c', int)
                pb_BOXING_ARG_CASE('C', int)
                pb_BOXING_ARG_CASE('s', int)
                pb_BOXING_ARG_CASE('S', int)
                pb_BOXING_ARG_CASE('i', int)
                pb_BOXING_ARG_CASE('I', unsigned int)
                pb_BOXING_ARG_CASE('l', long)
                pb_BOXING_ARG_CASE('L', unsigned long)
                pb_BOXING_ARG_CASE('q', long long)
                pb_BOXING_ARG_CASE('Q', unsigned long long)
                pb_BOXING_ARG_CASE('f', double)
                pb_BOXING_ARG_CASE('d', double)
                pb_BOXING_ARG_CASE('B', int)
                
            case ':': {
                SEL value = va_arg(argList, SEL);
                NSString *selValueName = NSStringFromSelector(value);
                [argumentsBoxingArray addObject:selValueName];
            }
                break;
            case '{': {
                NSString *typeString = pb_extractStructName([NSString stringWithUTF8String:argumentType]);
#define pb_FWD_ARG_STRUCT(_type, _methodName) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type val = va_arg(argList, _type);\
NSValue* value = [NSValue _methodName:val];\
[argumentsBoxingArray addObject:value];  \
break; \
}
                pb_FWD_ARG_STRUCT(CGRect, valueWithCGRect)
                pb_FWD_ARG_STRUCT(CGPoint, valueWithCGPoint)
                pb_FWD_ARG_STRUCT(CGSize, valueWithCGSize)
                pb_FWD_ARG_STRUCT(NSRange, valueWithRange)
                pb_FWD_ARG_STRUCT(CGAffineTransform, valueWithCGAffineTransform)
                pb_FWD_ARG_STRUCT(UIEdgeInsets, valueWithUIEdgeInsets)
                pb_FWD_ARG_STRUCT(UIOffset, valueWithUIOffset)
                pb_FWD_ARG_STRUCT(CGVector, valueWithCGVector)
            }
                break;
            case '*':{
                pb_generateError(@"unsupported char* argumenst",error);
                return nil;
            }
                break;
            case '^': {
                void *value = va_arg(argList, void**);
                pb_pointer *pointerObj = [[pb_pointer alloc]init];
                pointerObj.pointer = value;
                [argumentsBoxingArray addObject:pointerObj];
            }
                break;
            case '#': {
                Class value = va_arg(argList, Class);
                [argumentsBoxingArray addObject:(id)value];
                //                pb_generateError(@"unsupported class argumenst",error);
                //                return nil;
            }
                break;
            case '@':{
                id value = va_arg(argList, id);
                if (value) {
                    [argumentsBoxingArray addObject:value];
                }else{
                    [argumentsBoxingArray addObject:[pb_nilObject new]];
                }
            }
                break;
            default: {
                pb_generateError(@"unsupported argumenst",error);
                return nil;
            }
        }
    }
    return [argumentsBoxingArray copy];
}

static id pb_targetCallSelectorWithArgumentError(id target, SEL selector, NSArray *argsArr, NSError *__autoreleasing *error){
    
    Class cls = [target class];
    NSMethodSignature *methodSignature = pb_getMethodSignature(cls, selector);
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:target];
    [invocation setSelector:selector];
    
    NSMutableArray* _markArray;
    
    for (int i = 2; i< [methodSignature numberOfArguments]; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        id valObj = argsArr[i-2];
        switch (argumentType[0]=='r'?argumentType[1]:argumentType[0]) {
#define pb_CALL_ARG_CASE(_typeString, _type, _selector) \
case _typeString: {                              \
_type value = [valObj _selector];                     \
[invocation setArgument:&value atIndex:i];\
break; \
}
                pb_CALL_ARG_CASE('c', char, charValue)
                pb_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
                pb_CALL_ARG_CASE('s', short, shortValue)
                pb_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
                pb_CALL_ARG_CASE('i', int, intValue)
                pb_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
                pb_CALL_ARG_CASE('l', long, longValue)
                pb_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
                pb_CALL_ARG_CASE('q', long long, longLongValue)
                pb_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                pb_CALL_ARG_CASE('f', float, floatValue)
                pb_CALL_ARG_CASE('d', double, doubleValue)
                pb_CALL_ARG_CASE('B', BOOL, boolValue)
                
            case ':':{
                NSString *selName = valObj;
                SEL selValue = NSSelectorFromString(selName);
                [invocation setArgument:&selValue atIndex:i];
            }
                break;
            case '{':{
                NSString *typeString = pb_extractStructName([NSString stringWithUTF8String:argumentType]);
                NSValue *val = (NSValue *)valObj;
#define pb_CALL_ARG_STRUCT(_type, _methodName) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type value = [val _methodName];  \
[invocation setArgument:&value atIndex:i];  \
break; \
}
                pb_CALL_ARG_STRUCT(CGRect, CGRectValue)
                pb_CALL_ARG_STRUCT(CGPoint, CGPointValue)
                pb_CALL_ARG_STRUCT(CGSize, CGSizeValue)
                pb_CALL_ARG_STRUCT(NSRange, rangeValue)
                pb_CALL_ARG_STRUCT(CGAffineTransform, CGAffineTransformValue)
                pb_CALL_ARG_STRUCT(UIEdgeInsets, UIEdgeInsetsValue)
                pb_CALL_ARG_STRUCT(UIOffset, UIOffsetValue)
                pb_CALL_ARG_STRUCT(CGVector, CGVectorValue)
            }
                break;
            case '*':{
                NSCAssert(NO, @"argument boxing wrong,char* is not supported");
            }
                break;
            case '^':{
                pb_pointer *value = valObj;
                void *pointer = value.pointer;
                id obj = *((__unsafe_unretained id *)pointer);
                if (!obj) {
                    if (argumentType[1] == '@') {
                        if (!_markArray) {
                            _markArray = [[NSMutableArray alloc] init];
                        }
                        [_markArray addObject:valObj];
                    }
                }
                [invocation setArgument:&pointer atIndex:i];
            }
                break;
            case '#':{
                [invocation setArgument:&valObj atIndex:i];
            }
                break;
            default:{
                if ([valObj isKindOfClass:[pb_nilObject class]]) {
                    [invocation setArgument:&pbnilPointer atIndex:i];
                }else{
                    [invocation setArgument:&valObj atIndex:i];
                }
            }
        }
    }
    
    [invocation invoke];
    
    if ([_markArray count] > 0) {
        for (pb_pointer *pointerObj in _markArray) {
            void *pointer = pointerObj.pointer;
            id obj = *((__unsafe_unretained id *)pointer);
            if (obj) {
                CFRetain((__bridge CFTypeRef)(obj));
            }
        }
    }
    
    const char *returnType = [methodSignature methodReturnType];
    NSString *selName = pb_selectorName(selector);
    if (strncmp(returnType, "v", 1) != 0 ) {
        if (strncmp(returnType, "@", 1) == 0) {
            void *result;
            [invocation getReturnValue:&result];
            
            if (result == NULL) {
                return nil;
            }
            
            id returnValue;
            if ([selName isEqualToString:@"alloc"] || [selName isEqualToString:@"new"] || [selName isEqualToString:@"copy"] || [selName isEqualToString:@"mutableCopy"]) {
                returnValue = (__bridge_transfer id)result;
            }else{
                returnValue = (__bridge id)result;
            }
            return returnValue;
            
        } else {
            switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
                    
#define pb_CALL_RET_CASE(_typeString, _type) \
case _typeString: {                              \
_type returnValue; \
[invocation getReturnValue:&returnValue];\
return @(returnValue); \
break; \
}
                    pb_CALL_RET_CASE('c', char)
                    pb_CALL_RET_CASE('C', unsigned char)
                    pb_CALL_RET_CASE('s', short)
                    pb_CALL_RET_CASE('S', unsigned short)
                    pb_CALL_RET_CASE('i', int)
                    pb_CALL_RET_CASE('I', unsigned int)
                    pb_CALL_RET_CASE('l', long)
                    pb_CALL_RET_CASE('L', unsigned long)
                    pb_CALL_RET_CASE('q', long long)
                    pb_CALL_RET_CASE('Q', unsigned long long)
                    pb_CALL_RET_CASE('f', float)
                    pb_CALL_RET_CASE('d', double)
                    pb_CALL_RET_CASE('B', BOOL)
                    
                case '{': {
                    NSString *typeString = pb_extractStructName([NSString stringWithUTF8String:returnType]);
#define pb_CALL_RET_STRUCT(_type) \
if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
_type result;   \
[invocation getReturnValue:&result];\
NSValue * returnValue = [NSValue valueWithBytes:&(result) objCType:@encode(_type)];\
return returnValue;\
}
                    pb_CALL_RET_STRUCT(CGRect)
                    pb_CALL_RET_STRUCT(CGPoint)
                    pb_CALL_RET_STRUCT(CGSize)
                    pb_CALL_RET_STRUCT(NSRange)
                    pb_CALL_RET_STRUCT(CGAffineTransform)
                    pb_CALL_RET_STRUCT(UIEdgeInsets)
                    pb_CALL_RET_STRUCT(UIOffset)
                    pb_CALL_RET_STRUCT(CGVector)
                }
                    break;
                case '*':{
                    
                }
                    break;
                case '^': {
                    
                }
                    break;
                case '#': {
                    
                }
                    break;
            }
            return nil;
        }
    }
    return nil;
};

#pragma mark -- NSString --

@implementation NSString (PBRunner)

- (id)pb_generateInstanceByInitMethod:(NSString *)selString withError:(NSError * _Nullable __autoreleasing *)error, ... {
    
    Class aClass = NSClassFromString(self);
    if (!aClass) {
        NSString* errorStr = [NSString stringWithFormat:@"unrecognized className (%@)", self];
        pb_generateError(errorStr,error);
        return nil;
    }
    
    SEL selector = NSSelectorFromString(selString);
    //获取参数&方法签名
    va_list argList;
    va_start(argList, error);
    NSArray* boxingArguments = pb_targetBoxingArguments(argList, aClass, selector, error);
    va_end(argList);
    
    if (!boxingArguments) {
        return nil;
    }
    id allocObj = [aClass alloc];
    return pb_targetCallSelectorWithArgumentError(allocObj, selector, boxingArguments, error);
}

@end

@implementation NSObject (PBRunner)

- (id)pb_instanceCallMethod:(NSString *)selString withError:(NSError * _Nullable __autoreleasing *)error, ... {
    va_list argList;
    va_start(argList, error);
    SEL selector = NSSelectorFromString(selString);
    NSArray* boxingArguments = pb_targetBoxingArguments(argList, [self class], selector, error);
    va_end(argList);
    
    if (!boxingArguments) {
        return nil;
    }
    //wether class's method is responder
    if (![self respondsToSelector:selector]) {
        return nil;
    }
    return pb_targetCallSelectorWithArgumentError(self, selector, boxingArguments, error);
}

@end