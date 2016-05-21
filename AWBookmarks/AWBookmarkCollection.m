//
//  AWBookmarkCollection.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/21/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkCollection.h"
#import "AWBookmarkEntry.h"
#import "IDEHelpers.h"

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
    
    // Get the selected values
    IDESourceCodeEditor* editor = [IDEHelpers currentEditor];
    NSTextView* textView = editor.textView;
    NSString *wholeText = textView.string;
    NSRange selectedLettersRange = textView.selectedRange;
    NSRange selectedLineAllCharactersRange = [wholeText lineRangeForRange:selectedLettersRange];
    NSString *lineText = [wholeText substringWithRange:selectedLineAllCharactersRange];
    
    NSUInteger lineNumber = 1;
    for(NSUInteger i = 0; i < selectedLettersRange.location; i++)
    {
        if([[NSCharacterSet newlineCharacterSet] characterIsMember:[wholeText characterAtIndex:i]])
        {
            lineNumber++;
        }
    }
    
//    NSArray *lines = [wholeText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//    NSUInteger lineNumber = NSNotFound;
//    
//    NSUInteger index = [[wholeText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]
//                        indexOfObjectPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
//        return [obj isEqualToString:lineText];
//    }];
//    
    
    AWBookmarkEntry *newEntry = [[AWBookmarkEntry alloc] init];
    newEntry.lineText = lineText;
    newEntry.filePath = @"/Users/amanda/hey/what/up.dat";
    newEntry.lineNumber = @(lineNumber);
    
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
