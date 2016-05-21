//
//  AWBookmarkCollection.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/21/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkCollection.h"
#import "AWBookmarkEntry.h"

@interface AWBookmarkCollection ()

@property NSMutableArray *bookmarks;

@end

@implementation AWBookmarkCollection

- (id)init
{
    if(self = [super init])
    {
        self.bookmarks = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performBookmarkThisLine:) name:@"AW_contextMenuBookmarkOptionSelected" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)performBookmarkThisLine:(NSNotification *)notif
{
    AWBookmarkEntry *newEntry = [[AWBookmarkEntry alloc] init];
    newEntry.lineText = @"hey what's up";
    newEntry.filePath = @"/Users/amanda/hey/what/up.dat";
    newEntry.lineNumber = @(42);
    
    if(![self.bookmarks containsObject:newEntry])
    {
        [self.bookmarks addObject:newEntry];
    }
    
    [self saveBookmarks];
}

- (NSString *)serialize
{
    return @"hey here's some serialized objects";
}

- (void)saveBookmarks
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths firstObject];
    
    directory = [directory stringByAppendingPathComponent:@"AWBookmarks"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:directory])
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSString *filePath = [directory  stringByAppendingPathComponent:@"bookmarks.dat"];
    NSError *fileWritingError;
    
    NSString *value = [self serialize];
    [value writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&fileWritingError];
}

@end
