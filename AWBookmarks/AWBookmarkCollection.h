//
//  AWBookmarkCollection.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/21/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkEntry.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface AWBookmarkCollection : NSObject <NSTableViewDataSource, NSCoding>

@property (readonly, nonatomic) NSUInteger count;

+ (NSString *)savedBookmarksFilePath;

- (AWBookmarkEntry *)objectAtIndex:(NSUInteger)index;
- (void)resolveAllBookmarks;
- (void)deleteBookmarkEntry:(AWBookmarkEntry *)entry;
- (NSArray<NSNumber *> *)lineNumbersForURL:(NSURL *)url;
- (NSArray<AWBookmarkEntry *> *)bookmarksForURL:(NSURL *)url;
- (NSArray *)bookmarksInDocumentWithText:(NSString *)textOfDocument;
- (AWBookmarkEntry *)bookmarkForUUID:(UUID *)uuid;
- (void)performBookmarkThisLine;
- (NSUInteger)indexOfObject:(AWBookmarkEntry *)anObject;
- (BOOL)containsObject:(AWBookmarkEntry *)anObject;
- (BOOL)containsObjectWithUUID:(UUID *)uuid;
- (AWBookmarkEntry *)bookmarkEntryForCurrentContext;

@end
