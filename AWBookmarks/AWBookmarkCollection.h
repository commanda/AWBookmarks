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

@interface AWBookmarkCollection : NSObject <NSTableViewDataSource, NSCoding>

@property (readonly, nonatomic) NSUInteger count;

+ (NSString *)savedBookmarksFilePath;

- (AWBookmarkEntry *)objectAtIndex:(NSUInteger)index;
- (void)resolveAllBookmarks;
- (void)deleteBookmarkEntry:(AWBookmarkEntry *)entry;
- (NSArray *)lineNumbersForURL:(NSURL *)url;
- (void)performBookmarkThisLine;

@end
