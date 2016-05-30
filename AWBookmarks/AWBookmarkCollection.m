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
#import "CommonDefines.h"

@interface AWBookmarkCollection ()

@property NSString *projectDir;
@property NSString *projectName;

@end

@implementation AWBookmarkCollection

- (id)init
{
    if(self = [super init])
    {
        self.bookmarks = [[NSMutableArray alloc] init];
        
        // Just for testing, have some items in the collection
        /*
         <__NSArrayM 0x60800105acd0>(
         <AWBookmarkEntry: 0x608006e2bfe0>
         filePath: file:///Users/amanda/Playpen/AWBookmarks/AWBookmarks/AWBookmarksWindowController.h
         lineNumber: 12
         lineText:@interface AWBookmarksWindowController : NSWindowController
         ,
         <AWBookmarkEntry: 0x60800662e560>
         filePath: file:///Users/amanda/Playpen/AWBookmarks/AWBookmarks/AWBookmarksWindowController.h
         lineNumber: 14
         lineText:@property (strong) AWBookmarkCollection *bookmarkCollection;
         
         )
         */
        
        AWBookmarkEntry *one = [[AWBookmarkEntry alloc] init];
        one.filePath = [NSURL URLWithString:@"file:///Users/amanda/Playpen/AWBookmarks/AWBookmarks/AWBookmarksWindowController.h"];
        one.lineNumber = @(12);
        one.lineText = @"@@interface AWBookmarksWindowController : NSWindowController";
        [self.bookmarks addObject:one];
        
        AWBookmarkEntry *two = [[AWBookmarkEntry alloc] init];
        two.filePath = [NSURL URLWithString:@"file:///Users/amanda/Playpen/AWBookmarks/AWBookmarks/AWBookmarksWindowController.h"];
        two.lineNumber = @(14);
        two.lineText = @"@@property (strong) AWBookmarkCollection *bookmarkCollection;";
        [self.bookmarks addObject:two];
        
        
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
    
    NSURL *url = [[IDEHelpers currentSourceCodeDocument] fileURL];
    
    AWBookmarkEntry *newEntry = [[AWBookmarkEntry alloc] init];
    newEntry.lineText = lineText;
    newEntry.filePath = url;
    newEntry.lineNumber = @(lineNumber);
    
    if(![self.bookmarks containsObject:newEntry])
    {
        [self.bookmarks addObject:newEntry];
        DLOG(@"added new bookmark entry:\n%@", newEntry);
    }
    
    [self saveBookmarks];
}

- (NSString *)serialize
{
    return @"hey here's some serialized objects";
}

- (void)saveBookmarks
{
    NSString* projectPath = [[IDEHelpers currentWorkspaceDocument].workspace.representingFilePath.fileURL path];
    self.projectDir = [projectPath stringByDeletingLastPathComponent];
    self.projectName = [[projectPath lastPathComponent] stringByDeletingPathExtension];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths firstObject];
    
    directory = [[directory stringByAppendingPathComponent:@"AWBookmarks"] stringByAppendingPathComponent:self.projectName];
    
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
