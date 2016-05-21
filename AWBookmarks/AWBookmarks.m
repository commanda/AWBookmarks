//
//  AWBookmarks.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/17/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarks.h"
#import "CommonDefines.h"
#import "AWBookmarksWindowController.h"

@interface AWBookmarks()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (strong) AWBookmarksWindowController *windowController;
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification:)
                                                     name:NSMenuDidBeginTrackingNotification
                                                   object:nil];
    }
    return self;
}

- (void)handleNotification:(NSNotification *)notif
{
    NSMenu *contextMenu = (NSMenu *)notif.object;
    [contextMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *addBookmarkMenuItem = [[NSMenuItem alloc] initWithTitle:@"Bookmark This Line" action:@selector(contextMenuBookmarkOptionSelected) keyEquivalent:@""];
    addBookmarkMenuItem.target = self;
    [contextMenu addItem:addBookmarkMenuItem];
    [contextMenu addItem:[NSMenuItem separatorItem]];
}

//- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
//{
//    return YES;
//}

- (void)contextMenuBookmarkOptionSelected
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert runModal];
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

- (void)toggleBookmarksWindow
{
    // Show/hide the bookmarks window
    if(!self.windowController.window.isVisible)
    {
        if(self.windowController == nil)
        {
            self.windowController = [[AWBookmarksWindowController alloc] initWithWindowNibName:@"AWBookmarksWindowController"];
        }
        
        [self.windowController.window makeKeyAndOrderFront:nil];
        
    }
    else
    {
        [self.windowController close];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
