//
//  AWBookmarkCollection.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/21/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "AWBookmarkEntry.h"

@interface AWBookmarkCollection : NSObject <NSTableViewDataSource>

@property (readonly, nonatomic) NSUInteger count;

- (AWBookmarkEntry *)objectAtIndex:(NSUInteger)index;
- (void)resolveAllBookmarks;
- (void)deleteBookmarkEntry:(AWBookmarkEntry *)entry;

@end
