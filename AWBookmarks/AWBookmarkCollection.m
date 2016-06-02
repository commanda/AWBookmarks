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
#import "Aspects.h"

@interface AWBookmarkCollection ()


@property (strong) NSMutableArray *bookmarks;
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
         filePath: file:///Users/amanda/Playpen/Rayrolling/Rayrolling/Rayrolling.m
         lineNumber: 77
         lineText:    [[NSNotificationCenter defaultCenter] removeObserver:self];
         */
        
//        AWBookmarkEntry *one = [[AWBookmarkEntry alloc] init];
//        one.filePath = [NSURL URLWithString:@"file:///Users/amanda/Playpen/Rayrolling/Rayrolling/Rayrolling.m"];
//        one.lineNumber = @(54);
//        one.lineText = @"   [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil]";
//        [self.bookmarks addObject:one];
        
//        AWBookmarkEntry *two = [[AWBookmarkEntry alloc] init];
//        two.filePath = [NSURL URLWithString:@"file:///Users/amanda/Playpen/AWBookmarks/AWBookmarks/AWBookmarksWindowController.h"];
//        two.lineNumber = @(14);
//        two.lineText = @"@@property (strong) AWBookmarkCollection *bookmarkCollection;";
//        [self.bookmarks addObject:two];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performBookmarkThisLine:) name:@"AW_contextMenuBookmarkOptionSelected" object:nil];
        
        [self swizzleTextChangedInTextView];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)performBookmarkThisLine:(NSNotification *)notif
{
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
    newEntry.fileURL = url;
    newEntry.lineNumber = @(lineNumber);
    
    if(![self.bookmarks containsObject:newEntry])
    {
        [self willChangeValueForKey:@"count"];
        [self.bookmarks addObject:newEntry];
        [self didChangeValueForKey:@"count"];
    }
    
    [self saveBookmarks];
}

- (AWBookmarkEntry *)objectAtIndex:(NSUInteger)index
{
    if(index < self.bookmarks.count)
    {
        return self.bookmarks[index];
    }
    return nil;
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

- (void)resolveAllBookmarks
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // In case any of our bookmarks have changed location, or their text has changed a little on the line, or been deleted, update their entries

        [self willChangeValueForKey:@"count"];
        [self.bookmarks makeObjectsPerformSelector:@selector(resolve)];
        
        for(AWBookmarkEntry *entry in [self.bookmarks copy])
        {
            if(entry.toBeDeleted)
            {
                [self.bookmarks removeObject:entry];
            }
        }
        
        [self didChangeValueForKey:@"count"];
        
    });
}

#pragma NSTableViewDataSource protocol methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return self.bookmarks.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    id toReturn;
    
    AWBookmarkEntry *entry = [self.bookmarks objectAtIndex:rowIndex];
    
    if([aTableColumn.identifier hasSuffix:@"0"])
    {
        toReturn = entry.fileURL.absoluteString.lastPathComponent;
    }
    else if([aTableColumn.identifier hasSuffix:@"1"])
    {
        toReturn = entry.lineNumber;
    }
    else if([aTableColumn.identifier hasSuffix:@"2"])
    {
        toReturn = entry.lineText;
    }
    
    return toReturn;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
    
}

#pragma mark - Swizzling

#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"

- (void)swizzleTextChangedInTextView
{
    __weak AWBookmarkCollection *weakSelf = self;
    NSString *className = @"DVTSourceTextView";
    Class c = NSClassFromString(className);
    [c aspect_hookSelector:@selector(didChangeText)
               withOptions:AspectPositionAfter
                usingBlock:^(id<AspectInfo> info) {
                    AWBookmarkCollection *strongSelf = weakSelf;
                    [strongSelf resolveAllBookmarks];
                }
                     error:nil];
}

#pragma clang diagnostic pop

@end
