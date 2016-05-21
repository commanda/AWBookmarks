//
//  AWContextMenuHandler.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWContextMenuHandler.h"

@implementation AWContextMenuHandler

- (id)init
{
    if(self = [super init])
    {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification:)
                                                     name:NSMenuDidBeginTrackingNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)contextMenuBookmarkOptionSelected
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert runModal];
}

@end
