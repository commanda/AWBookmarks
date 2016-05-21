//
//  AWContextMenuHandler.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWContextMenuHandler.h"
#import "Aspects.h"
#import "CommonDefines.h"

@interface AWContextMenuHandler ()

@property NSMenuItem *addBookmarkMenuItem;

@end

@implementation AWContextMenuHandler


- (id)init
{
    if(self = [super init])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.addBookmarkMenuItem = [[NSMenuItem alloc] initWithTitle:@"Bookmark This Line" action:@selector(contextMenuBookmarkOptionSelected) keyEquivalent:@""];
            self.addBookmarkMenuItem.target = self;
            
            [self swizzleMenuForEventInTextView];
            //[self swizzleSetEnabledInNSMenuItem];
        });
    }
    return self;
}

- (void)contextMenuBookmarkOptionSelected
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert runModal];
}

#pragma mark - Swizzling

#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"

- (void)swizzleMenuForEventInTextView
{
    NSString *className = @"DVTSourceTextView";
    Class c = NSClassFromString(className);
    [c aspect_hookSelector:@selector(menuForEvent:) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> info, NSEvent *event) {
        NSObject *object = info.instance;
        DLOG(@"object: %@", object);
        
        if(![object isKindOfClass:NSClassFromString(className)]) {
            [info.originalInvocation invoke];
        }
        else {
            NSInvocation *invocation = info.originalInvocation;
            NSMenu *contextMenu;
            [invocation invoke];
            [invocation getReturnValue:&contextMenu];
            
            DLOG(@"return value: %@", contextMenu);
//            CFRetain((__bridge CFTypeRef)(contextMenu)); // need to retain return value so it isn't dealloced before being returned
//            id holder = [info.instance performSelector:(@selector(realDataSource))];
//            if ([holder isKindOfClass:NSClassFromString(@"IDEIssueNavigator")] && [contextMenu itemWithTitle:@"Copy Issue"]==nil)
//            {
//                if ([_copyIssueContextMenuItem menu] != nil) {
//                    NSMenu *oldContextMenu = [_copyIssueContextMenuItem menu];
//                    [oldContextMenu removeItem:_copyIssueContextMenuItem];
//                    [oldContextMenu removeItem:_contextMenuSearchMenuItem];
//                }
//                
//                [contextMenu insertItem:_copyIssueContextMenuItem atIndex:1];
//                [contextMenu insertItem:[NSMenuItem separatorItem] atIndex:2];
//                [contextMenu insertItem:_contextMenuSearchMenuItem atIndex:3];
//                [contextMenu insertItem:[NSMenuItem separatorItem] atIndex:4];
//            }
//            [invocation setReturnValue:&contextMenu];
        }
    } error:NULL];
}

// This will add logic to the context menu's enable setter to determine whether to enable the custom context menu items
- (void)swizzleSetEnabledInNSMenuItem {
    [NSMenuItem aspect_hookSelector:@selector(setEnabled:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info, BOOL enabled) {
        NSMenuItem *item = info.instance;
        if ([item.title isEqualToString:@"Copy"] && [item.menu.title isEqualToString:@"Issue navigator contextual menu"])
        {
//            _enableContextMenuItems = [item isEnabled];
//            [self getStringOntoClipboardForItemsInContextMenu:item];
        }
    } error:NULL];
}


#pragma clang diagnostic pop

@end
