//
//  StingerParams.m
//  Stinger
//
//  Created by Assuner on 2018/1/10.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "StingerParams.h"
#import <objc/runtime.h>

@interface NSInvocation (STInvoke)
- (void)invokeUsingIMP:(IMP)imp;
@end

@interface StingerParams ()
@property (nonatomic, strong) NSString *types;
@property (nonatomic) SEL sel;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) void **args;
@property (nonatomic) NSArray *argumentTypes;
@property (nonatomic) NSMutableArray *arguments;
@end

@implementation StingerParams

- (instancetype)initWithType:(NSString *)types originalIMP:(IMP)imp sel:(SEL)sel args:(void **)args argumentTypes:(NSArray *)argumentTypes {
  if (self = [super init]) {
    _types = types;
    _sel = sel;
    _originalIMP = imp;
    _args = args;
    _argumentTypes = argumentTypes;
    [self st_genarateArguments];
  }
  return self;
}

- (id)slf {
  void **slfPointer = _args[0];
  return (__bridge id)(*slfPointer);
}

- (SEL)sel {
  return _sel;
}

- (NSArray *)arguments {
    return [_arguments copy];
}

- (NSString *)typeEncoding {
    return _types;
}

/// 修改函数参数
/// - Parameters:
///   - arg: 对应的参数，值类型请转换为NSValue传递
///   - idx: 序号，默认从0开始
- (void)setArgument:(id)arg atIndex:(NSInteger)idx {
    _arguments[idx]= arg;
    NSString *argTypeStr = _argumentTypes[idx + 2];
    const char *argType = argTypeStr.UTF8String;
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        void **objPointer = _args[idx + 2];
        *objPointer = (__bridge void *)(arg);
        return;
    }
    if ([arg isKindOfClass:NSValue.class]) {
        if (@available(iOS 11.0, *)) {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(argType, &valueSize, NULL);
            [(NSValue *)arg getValue:_args[idx + 2] size:valueSize];
        } else {
            [(NSValue *)arg getValue:_args[idx + 2]];
        }
    }
}

- (void)invokeAndGetOriginalRetValue:(void *)retLoc {
  NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:_types.UTF8String];
  NSInteger count = signature.numberOfArguments;
  NSInvocation *originalInvocation = [NSInvocation invocationWithMethodSignature:signature];
  for (int i = 0; i < count; i ++) {
    [originalInvocation setArgument:_args[i] atIndex:i];
  }
  [originalInvocation invokeUsingIMP:_originalIMP];
  if (originalInvocation.methodSignature.methodReturnLength && !(retLoc == NULL)) {
    [originalInvocation getReturnValue:retLoc];
  }
}

#pragma - mark Private

- (void)st_genarateArguments {
    _arguments = [NSMutableArray array];
    for (NSUInteger i = 2; i < _argumentTypes.count; i++) {
        id argument = [self st_argumentWithType:_argumentTypes[i] index:i];
        [_arguments addObject:argument ?: NSNull.null];
    }
}

- (id)st_argumentWithType:(NSString *)type index:(NSUInteger)index {
    const char *argType = type.UTF8String;
    // Skip const type qualifier.
    if (argType[0] == _C_CONST) argType++;

#define WRAP_AND_RETURN(type) do { type val = 0; val = *((type *)_args[index]); return @(val); } while (0)
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        void **objPointer = _args[index];
        return (__bridge id)(*objPointer);
    } else if (strcmp(argType, @encode(SEL)) == 0) {
        SEL selector = *((SEL *)_args[index]);
        return NSStringFromSelector(selector);
    } else if (strcmp(argType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    } else if (strcmp(argType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    } else if (strcmp(argType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    } else if (strcmp(argType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    } else if (strcmp(argType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    } else if (strcmp(argType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(bool)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        WRAP_AND_RETURN(const char *);
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        void **blockPointer = _args[index];
        __unsafe_unretained id block = (__bridge id)(*blockPointer);
        return [block copy];
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(argType, &valueSize, NULL);

        unsigned char valueBytes[valueSize];
        memcpy(valueBytes, _args[index], valueSize);
        
        return [NSValue valueWithBytes:valueBytes objCType:argType];
    }
    return nil;
#undef WRAP_AND_RETURN
}

@end
