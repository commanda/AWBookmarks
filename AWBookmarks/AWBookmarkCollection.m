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

@end

@implementation AWBookmarkCollection


+ (NSString *)savedBookmarksFilePath
{
    NSString *directory = [AWBookmarksPlugin pathToApplicationSupport];
    
    NSString *filePath = [directory stringByAppendingPathComponent:@"bookmarks.dat"];
    
    return filePath;
}

- (id)init
{
    if(self = [super init])
    {
        [self swizzleTextChangedInTextView];
        self.bookmarks = [@[] mutableCopy];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if(self = [self init])
    {
        self.bookmarks = [decoder decodeObjectForKey:@"bookmarkEntries"];
        
        if(!self.bookmarks)
        {
            self.bookmarks = [@[] mutableCopy];
        }
        
        for(AWBookmarkEntry *entry in self.bookmarks)
        {
            [self observeBookmarkEntry:entry];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.bookmarks forKey:@"bookmarkEntries"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeBookmarkEntry:(AWBookmarkEntry *)entry
{
    // Watch this entry for changes
    [entry addObserver:self forKeyPath:@"changed" options:0 context:nil];
    [entry addObserver:self forKeyPath:@"toBeDeleted" options:0 context:nil];
}

- (void)unobserveBookmarkEntry:(AWBookmarkEntry *)entry
{
    [entry removeObserver:self forKeyPath:@"changed"];
    [entry removeObserver:self forKeyPath:@"toBeDeleted"];
}

- (NSUInteger)count
{
    return self.bookmarks.count;
}

- (void)performBookmarkThisLine
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
    
    if(url)
    {
        
        NSString* projectPath = [[IDEHelpers currentWorkspaceDocument].workspace.representingFilePath.fileURL path];
        
        AWBookmarkEntry *newEntry = [[AWBookmarkEntry alloc] init];
        newEntry.lineText = lineText;
        newEntry.fileURL = url;
        newEntry.lineNumber = @(lineNumber);
        newEntry.containingProjectURL = [NSURL fileURLWithPath:projectPath];
        
        if(![self.bookmarks containsObject:newEntry])
        {
            [self willChangeValueForKey:@"count"];
            [self.bookmarks addObject:newEntry];
            [self didChangeValueForKey:@"count"];
            
            [self observeBookmarkEntry:newEntry];
        }
        
        [self saveBookmarks];
    }
}

- (AWBookmarkEntry *)objectAtIndex:(NSUInteger)index
{
    if(index < self.bookmarks.count)
    {
        return self.bookmarks[index];
    }
    return nil;
}

- (void)deleteBookmarkEntry:(AWBookmarkEntry *)entry
{
    if([self.bookmarks containsObject:entry])
    {
        [self unobserveBookmarkEntry:entry];
        
        [self willChangeValueForKey:@"count"];
        [self.bookmarks removeObject:entry];
        [self didChangeValueForKey:@"count"];
        
        [self saveBookmarks];
    }
}

- (void)saveBookmarks
{
    [NSKeyedArchiver archiveRootObject:self toFile:[[self class] savedBookmarksFilePath]];
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
        [self deleteBookmarkEntry:object];
    }
    else if([keyPath isEqualToString:@"changed"])
    {
        [self willChangeValueForKey:@"count"];
        [self didChangeValueForKey:@"count"];
    }
}

- (NSArray *)lineNumbersForURL:(NSURL *)url
{
    NSMutableArray *toReturn = [@[] mutableCopy];
    for(AWBookmarkEntry *entry in self.bookmarks)
    {
        if([entry.fileURL isEqual:url])
        {
            [toReturn addObject:entry.lineNumber];
        }
    }
    return toReturn;
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
