//
//  AWBookmarks.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/17/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarks.h"
#import "CommonDefines.h"

@interface AWBookmarks()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation AWBookmarks

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    // Create menu items, initialize UI, etc.
    // Sample Menu Item:
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Bookmarks"
                                                                action:@selector(toggleBookmarksWindow)
                                                         keyEquivalent:@"b"];
        [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

// Sample Action, for menu item:
- (void)toggleBookmarksWindow
{
    DLOG(@"wow");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
