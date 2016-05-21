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
        });
    }
    return self;
}


- (void)contextMenuBookmarkOptionSelected
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AW_contextMenuBookmarkOptionSelected" object:nil];
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
            CFRetain((__bridge CFTypeRef)(contextMenu)); // need to retain return value so it isn't dealloced before being returned
            
            if(self.addBookmarkMenuItem.menu == nil)
            {
                [contextMenu addItem:self.addBookmarkMenuItem];
            }

            [invocation setReturnValue:&contextMenu];
        }
    } error:NULL];
}

#pragma clang diagnostic pop

@end
