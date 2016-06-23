//
//  AWBookmarksWindowController.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkCollection.h"
#import <Cocoa/Cocoa.h>

@interface AWBookmarksWindowController : NSWindowController <NSTableViewDelegate>

@property (strong) AWBookmarkCollection *bookmarkCollection;


@end
