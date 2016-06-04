//
//  AWBookmarksPlugin.m
//  AWBookmarksPlugin
//
//  Created by Amanda Wixted on 5/17/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarksPlugin.h"
#import "CommonDefines.h"
#import "AWBookmarksWindowController.h"
#import "AWContextMenuHandler.h"
#import "AWBookmarkCollection.h"
#import "AWGutterViewHandler.h"

@interface AWBookmarksPlugin()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (strong) AWBookmarksWindowController *windowController;
@property (strong) AWContextMenuHandler *contextMenuHandler;
@property (strong) AWBookmarkCollection *bookmarkCollection;

@end

@implementation AWBookmarksPlugin

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

+ (NSString *)pathToApplicationSupportForProjectName:(NSString *)projectName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths firstObject];
    
    directory = [[directory stringByAppendingPathComponent:@"AWBookmarks"] stringByAppendingPathComponent:projectName];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:directory])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return directory;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if(self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        
        self.contextMenuHandler = [[AWContextMenuHandler alloc] init];
        
        self.bookmarkCollection = [[AWBookmarkCollection alloc] init];
        
        [AWGutterViewHandler start];
        
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

- (void)toggleBookmarksWindow
{
    if(self.windowController == nil)
    {
        self.windowController = [[AWBookmarksWindowController alloc] initWithWindowNibName:@"AWBookmarksWindowController"];
        self.windowController.bookmarkCollection = self.bookmarkCollection;
    }
    
    [self.windowController.window makeKeyAndOrderFront:self.windowController];
    [self.windowController.window setOrderedIndex:0];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
