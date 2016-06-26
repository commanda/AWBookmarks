//
//  AWBookmarksWindowController.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarksWindowController.h"
#import "AWBookmarkEntry.h"
#import "Aspects.h"
#import "CommonDefines.h"

@interface AWDeleteButton : NSButton
@property AWBookmarkEntry *entry;
@end

@implementation AWDeleteButton

@end

@interface AWBookmarksWindowController ()
@property (strong) IBOutlet NSTableView *tableView;
@property (getter=isObservingBookmarksCount) BOOL observingBookmarksCount;
@property BOOL shouldReloadTableView;
@end

@implementation AWBookmarksWindowController


#define MAX_HIGHLIGHT_TRIES 100

+ (void)openItem:(AWBookmarkEntry *)item
{
    if(item)
    {
        NSString *containingProjectPath = item.containingProjectURL.path;
        NSString *path = item.fileURL.path;

        if(path)
        {

            // If this bookmark is in an xcode project, open that first
            [self openFile:containingProjectPath
                withVerifier:^BOOL(NSString *openedThing) {
                    return ([[IDEHelpers currentOpenProjectPath] isEqualToString:openedThing]);
                }
                andThen:^{

                    // Once that's open, (or if it doesn't exist) then open the file itself
                    [self openFile:path
                        withVerifier:^BOOL(NSString *openedThing) {
                            return [IDEHelpers currentSourceTextView] != nil;
                        }
                        andThen:^{

                            // Wait for the file to be open and then highlighting the line
                            [self highlightItemInOpenedFile:item];
                        }];
                }];
        }
    }
}

+ (void)openFile:(NSString *)filename withVerifier:(BOOL (^)(NSString *))verifier andThen:(void (^)(void))afterward
{
    if(filename)
    {
        id<NSApplicationDelegate> appDelegate = (id<NSApplicationDelegate>)[NSApp delegate];
        [appDelegate application:NSApp openFile:filename];

        __block int stopCounter = 0;
        void (^waitForFileOpen)();
        void (^__block __weak weakWaitForFileOpen)();
        weakWaitForFileOpen = waitForFileOpen = ^{

            // If the file is open, we're done
            if(verifier(filename))
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    afterward();
                });
            }
            else
            {
                // Otherwise, wait a bit and try again
                void (^strongWaitForFileOpen)() = weakWaitForFileOpen;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if(stopCounter < MAX_HIGHLIGHT_TRIES)
                    {
                        stopCounter++;
                        strongWaitForFileOpen();
                    }
                    else
                    {
                        // We couldn't verify that the file was opened, so just move on
                        afterward();
                    }
                });
            }
        };

        waitForFileOpen();
    }
    else
    {
        afterward();
    }
}

+ (void)highlightItemInOpenedFile:(AWBookmarkEntry *)item
{
    DVTSourceTextView *textView = [IDEHelpers currentSourceTextView];
    if(textView)
    {
        // Unfold the source, in case it is currently folded
        [textView unfoldAll:nil];

        [item highlightInTextView:textView];
    }
}

- (void)dealloc
{
    [self unobserveBookmarksCount];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.window.title = @"Bookmarks";

    self.tableView.dataSource = self.bookmarkCollection;

    [self observeBookmarksCount];
}

- (void)reloadData:(id)whatever
{
    if(self.shouldReloadTableView)
    {
        self.shouldReloadTableView = NO;
        [self.tableView reloadData];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    @synchronized(self)
    {
        if(!self.shouldReloadTableView)
        {
            self.shouldReloadTableView = YES;
            [[NSRunLoop mainRunLoop] performSelector:@selector(reloadData:) target:self argument:nil order:1 modes:@[ NSDefaultRunLoopMode ]];
        }
    }
}

- (void)observeBookmarksCount
{
    if(!self.isObservingBookmarksCount)
    {
        self.observingBookmarksCount = YES;
        [self.bookmarkCollection addObserver:self forKeyPath:@"count" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)unobserveBookmarksCount
{
    if(self.isObservingBookmarksCount)
    {
        self.observingBookmarksCount = NO;
        [self.bookmarkCollection removeObserver:self forKeyPath:@"count"];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger selectedRow = self.tableView.selectedRow;
    AWBookmarkEntry *entry = [self.bookmarkCollection objectAtIndex:selectedRow];

    // Open the file it references and scroll to that line
    [[self class] openItem:entry];

    [self.tableView deselectRow:selectedRow];
}

- (void)deletePressed:(id)sender
{
    AWDeleteButton *button = (AWDeleteButton *)sender;

    [self unobserveBookmarksCount];
    [self.tableView beginUpdates];
    [self.bookmarkCollection deleteBookmarkEntry:button.entry];
    button.entry = nil;
    NSInteger currentRow = [self.tableView rowForView:button];
    if(currentRow >= 0 && currentRow < self.tableView.numberOfRows)
    {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:currentRow];
        [self.tableView removeRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationEffectFade];
    }
    [self.tableView endUpdates];
    [self observeBookmarksCount];
}

static NSString *identifier = @"AWBookmarksTextCellIdentifier";
static NSString *buttonIdentifier = @"AWBookmarksDeleteButtonCellIdentifier";

- (NSView *)tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row
{
    NSView *toReturn;
    if([tableColumn.identifier isEqualToString:@"Delete?"])
    {
        // The delete button
        AWDeleteButton *button = [tableView makeViewWithIdentifier:buttonIdentifier owner:self];
        if(!button)
        {
            button = [[AWDeleteButton alloc] initWithFrame:CGRectMake(0, 0, tableColumn.width, tableView.rowHeight)];
            button.identifier = buttonIdentifier;
            button.target = self;
            button.action = @selector(deletePressed:);
            button.title = @"";
        }
        AWBookmarkEntry *entry = [self.bookmarkCollection objectAtIndex:row];
        button.entry = entry;
        toReturn = button;
    }
    else
    {
        // The three text fields - line number, line text, file path
        NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
        if(!textField)
        {
            textField = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, tableColumn.width, tableView.rowHeight)];
            textField.identifier = identifier;
            textField.editable = NO;
            textField.selectable = NO;
            textField.bezeled = NO;
            textField.bordered = NO;
            textField.backgroundColor = [NSColor clearColor];
        }
        toReturn = textField;
    }
    return toReturn;
}

@end
