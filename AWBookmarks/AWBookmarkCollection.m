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
#import "AWBookmarksPlugin.h"

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
        
        // Watch this entry for changes
        [newEntry addObserver:self forKeyPath:@"changed" options:0 context:nil];
        [newEntry addObserver:self forKeyPath:@"toBeDeleted" options:0 context:nil];
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
    NSMutableArray *uuids = [[NSMutableArray alloc] initWithCapacity:self.bookmarks.count];
    [self.bookmarks enumerateObjectsUsingBlock:^(AWBookmarkEntry *entry, NSUInteger idx, BOOL * _Nonnull stop){
        [uuids addObject:entry.uuid];
    }];
    
    return [uuids componentsJoinedByString:@", "];
}

- (void)saveBookmarks
{
    NSString* projectPath = [[IDEHelpers currentWorkspaceDocument].workspace.representingFilePath.fileURL path];
    self.projectDir = [projectPath stringByDeletingLastPathComponent];
    self.projectName = [[projectPath lastPathComponent] stringByDeletingPathExtension];
    
    NSString *directory = [AWBookmarksPlugin pathToApplicationSupportForProjectName:self.projectName];
    
    NSString *filePath = [directory  stringByAppendingPathComponent:@"bookmarks.dat"];
    NSError *fileWritingError;
    
    NSString *value = [self serialize];
    [value writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&fileWritingError];
}

- (void)resolveAllBookmarks
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // In case any of our bookmarks have changed location, or their text has changed a little on the line, or been deleted, update their entries
        [[self.bookmarks copy] makeObjectsPerformSelector:@selector(resolve)];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"toBeDeleted"])
    {
        [self willChangeValueForKey:@"count"];
        [self.bookmarks removeObject:object];
        [self didChangeValueForKey:@"count"];
    }
    else if([keyPath isEqualToString:@"changed"])
    {
        [self willChangeValueForKey:@"count"];
        [self didChangeValueForKey:@"count"];
    }
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
        toReturn = [entry.lineText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
