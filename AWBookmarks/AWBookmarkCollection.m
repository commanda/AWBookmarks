//
//  AWBookmarkCollection.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/21/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkCollection.h"
#import "AWBookmarkEntry.h"
#import "AWBookmarksPlugin.h"
#import "Aspects.h"
#import "CommonDefines.h"
#import "IDEHelpers.h"
#import "NSArray+EffectiveEquals.h"

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
        @try
        {
            self.bookmarks = [[decoder decodeObjectForKey:@"bookmarkEntries"] mutableCopy];
        }
        @catch(NSException *exception)
        {
            // An exception can be thrown if the .dat is corrupted and we try to decode it
            DLOG(@"bp");
        }

        for(AWBookmarkEntry *entry in self.bookmarks)
        {
            [self observeBookmarkEntry:entry];
        }

        [self resolveAllBookmarks];
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

- (NSString *)description
{
    NSMutableString *desc = [@"" mutableCopy];
    [desc appendString:[super description]];
    [desc appendString:@"\n"];
    for(int i = 0; i < self.bookmarks.count; i++)
    {
        [desc appendString:[NSString stringWithFormat:@"[%d]", i]];
        [desc appendString:[self.bookmarks[0] description]];
        [desc appendString:@"\n\n"];
    }
    return desc;
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

- (AWBookmarkEntry *)bookmarkEntryForCurrentContext
{
    AWBookmarkEntry *toReturn;

    DVTSourceTextView *textView = [IDEHelpers currentSourceTextView];
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
        AWBookmarkEntry *newEntry = [[AWBookmarkEntry alloc] init];
        newEntry.lineText = lineText;
        newEntry.fileURL = url;
        newEntry.lineNumber = @(lineNumber);

        // Store the URL of the xcodeproj that contains this file, unless it's not in a project, in which case it'll be "Autosave Information"
        NSString *projectPath = [[IDEHelpers currentWorkspaceDocument].workspace.representingFilePath.fileURL path];
        if([projectPath rangeOfString:@"Autosave Information"].location == NSNotFound)
        {
            newEntry.containingProjectURL = [NSURL fileURLWithPath:projectPath];
        }

        if(![self.bookmarks effectivelyContainsObject:newEntry])
        {
            toReturn = newEntry;
        }
        else
        {
            toReturn = [self.bookmarks objectAtIndex:[self.bookmarks effectiveIndexOfObject:newEntry]];
        }
    }
    return toReturn;
}

- (void)performBookmarkThisLine
{
    AWBookmarkEntry *entry = [self bookmarkEntryForCurrentContext];

    if(entry && ![self.bookmarks containsObject:entry])
    {
        [self willChangeValueForKey:@"count"];
        [self.bookmarks addObject:entry];
        [self didChangeValueForKey:@"count"];

        [self observeBookmarkEntry:entry];
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

- (NSUInteger)indexOfObject:(AWBookmarkEntry *)anObject
{
    return [self.bookmarks indexOfObject:anObject];
}

- (BOOL)containsObject:(AWBookmarkEntry *)anObject
{
    return [self.bookmarks containsObject:anObject];
}

- (BOOL)containsObjectWithUUID:(UUID *)uuid
{
    for(AWBookmarkEntry *entry in self.bookmarks)
    {
        if([entry.uuid isEqualToString:uuid])
        {
            return YES;
        }
    }
    return NO;
}

- (AWBookmarkEntry *)bookmarkForUUID:(UUID *)uuid
{
    for(AWBookmarkEntry *entry in self.bookmarks)
    {
        if([entry.uuid isEqualToString:uuid])
        {
            return entry;
        }
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"toBeDeleted"])
    {
        [self deleteBookmarkEntry:object];
    }
    else if([keyPath isEqualToString:@"changed"])
    {
        [self willChangeValueForKey:@"count"];
        [self didChangeValueForKey:@"count"];
        [self saveBookmarks];
    }
}

- (NSArray<NSNumber *> *)lineNumbersForURL:(NSURL *)url;
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

- (NSArray<AWBookmarkEntry *> *)bookmarksForURL:(NSURL *)url;
{
    NSMutableArray *toReturn = [@[] mutableCopy];
    for(AWBookmarkEntry *entry in self.bookmarks)
    {
        if([entry.fileURL isEqual:url])
        {
            [toReturn addObject:entry];
        }
    }
    return toReturn;
}

- (NSArray *)bookmarksInDocumentWithText:(NSString *)textOfDocument
{
    NSMutableSet *urls = [[NSMutableSet alloc] init];
    [self.bookmarks enumerateObjectsUsingBlock:^(AWBookmarkEntry *obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [urls addObject:obj.fileURL];
    }];

    NSMutableArray *entriesForTextDocument = [@[] mutableCopy];
    for(NSURL *url in urls)
    {
        NSString *textAtURL = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        if([textAtURL isEqualToString:textOfDocument])
        {
            [entriesForTextDocument addObjectsFromArray:[self bookmarksForURL:url]];
        }
    }
    return entriesForTextDocument;
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

    if([aTableColumn.identifier isEqualToString:@"File"])
    {
        toReturn = entry.fileURL.absoluteString.lastPathComponent;
    }
    else if([aTableColumn.identifier isEqualToString:@"Line #"])
    {
        toReturn = entry.lineNumber;
    }
    else if([aTableColumn.identifier isEqualToString:@"Line Content"])
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
