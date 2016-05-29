//
//  AWBookmarksPlugin.h
//  AWBookmarksPlugin
//
//  Created by Amanda Wixted on 5/17/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <AppKit/AppKit.h>

@class AWBookmarksPlugin;

static AWBookmarksPlugin *sharedPlugin;

@interface AWBookmarksPlugin : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end