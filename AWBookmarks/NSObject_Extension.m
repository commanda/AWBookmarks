//
//  NSObject_Extension.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/17/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//


#import "NSObject_Extension.h"
#import "AWBookmarks.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[AWBookmarks alloc] initWithBundle:plugin];
        });
    }
}
@end
