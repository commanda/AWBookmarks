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
@property (strong) AWGutterViewHandler *gutterViewHandler;

@end

@implementation AWBookmarksPlugin

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

+ (NSString *)pathToApplicationSupport
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths firstObject];
    
    directory = [directory stringByAppendingPathComponent:@"Xcode-AWBookmarks"];
    
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
        
        
        self.bookmarkCollection = [NSKeyedUnarchiver unarchiveObjectWithFile:[AWBookmarkCollection savedBookmarksFilePath]];
        if(!self.bookmarkCollection)
        {
            self.bookmarkCollection = [[AWBookmarkCollection alloc] init];
        }
        
        self.contextMenuHandler = [[AWContextMenuHandler alloc] initWithBookmarkCollection:self.bookmarkCollection];
        
        self.gutterViewHandler = [[AWGutterViewHandler alloc] initWithBookmarkCollection:self.bookmarkCollection];
        
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
    NSMenuItem *viewMenuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
    if (viewMenuItem) {
        [[viewMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Bookmarked Items"
                                                                action:@selector(showBookmarksWindow)
                                                         keyEquivalent:@"b"];
        [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask|NSCommandKeyMask];
        [actionMenuItem setTarget:self];
        [[viewMenuItem submenu] addItem:actionMenuItem];
    }
    
    NSMenuItem *editorMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if(editorMenuItem)
    {
        NSMenuItem *bookmarkThisLine = [[NSMenuItem alloc] initWithTitle:@"Bookmark Current Line"
                                                                  action:@selector(bookmarkCurrentLine)
                                                           keyEquivalent:@"b"];
        [bookmarkThisLine setKeyEquivalentModifierMask:NSControlKeyMask];
        [bookmarkThisLine setTarget:self];
        [[editorMenuItem submenu] addItem:bookmarkThisLine];
    }
}

- (void)showBookmarksWindow
{
    if(self.windowController == nil)
    {
        self.windowController = [[AWBookmarksWindowController alloc] initWithWindowNibName:@"AWBookmarksWindowController"];
        self.windowController.bookmarkCollection = self.bookmarkCollection;
    }
    
    [self.windowController.window makeKeyAndOrderFront:self.windowController];
    //[self.windowController.window setOrderedIndex:0];
}

- (void)bookmarkCurrentLine
{
    [self.bookmarkCollection performBookmarkThisLine];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
