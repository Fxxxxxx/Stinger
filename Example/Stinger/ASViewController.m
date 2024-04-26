//
//  ASViewController.m
//  Stinger
//
//  Created by Assuner on 12/05/2017.
//  Copyright (c) 2017 Assuner. All rights reserved.
//

#import "ASViewController.h"
#import <Stinger/Stinger.h>
#import <Aspects/Aspects.h>

@interface ASViewController ()

- (IBAction)test:(id)sender;

@end

@implementation ASViewController

- (void)methodA {
  
}

- (void)setFrame:(CGRect)rect {
  
}

- (BOOL)setFrame:(CGRect)rect object:(NSString *)obj num:(NSInteger)num {
    NSLog(@"origin fun: %@, %@, %ld", @(rect), obj, num);
    return YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.class st_hookInstanceMethod:@selector(methodA) option:STOptionBefore usingIdentifier:@"hook methodA before" withBlock:^(id<StingerParams> params) {

  }];
  [self.class st_hookInstanceMethod:@selector(methodA) option:STOptionAfter usingIdentifier:@"hook methodA after" withBlock:^(id<StingerParams> params) {

  }];
    
    [self.class st_hookInstanceMethod:@selector(setFrame:object:num:) option:STOptionAfter usingIdentifier:@"change arg" withBlock:^BOOL(id<StingerParams> params, CGRect rect, NSString *obj, NSInteger num) {
        [params setArgument:@(CGRectMake(5, 6, 7, 8)) atIndex:0];
        [params setArgument:@"hook success" atIndex:1];
        [params setArgument:@(num + 1) atIndex:2];
        BOOL returnValue;
        [params invokeAndGetOriginalRetValue:&returnValue];
        return returnValue;
    }];
    [self setFrame:CGRectMake(1, 2, 3, 4) object:@"not hook" num:111];
    
    
//  [self.class aspect_hookSelector:@selector(methodA) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
//
//  } error:nil];
//
//  [self.class aspect_hookSelector:@selector(methodA) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> params) {
//
//  } error:nil];
}

- (IBAction)test:(id)sender {
  for (NSInteger i = 0; i < 1000000; i++) {
    [self methodA];
  }
  NSLog(@"clicked!!");
  NSURL *url = [[NSURL alloc] initWithString:@"https://www.google.com"];
  [url st_hookInstanceMethod:@selector(absoluteString) option:(STOptionBefore) usingIdentifier:@"123" withBlock:^(id<StingerParams> params) {
      NSLog(@"");
  }];
  [url absoluteString];
}
@end
