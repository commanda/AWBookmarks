//
//  AWBookmarksWindowController.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarksWindowController.h"
#import "CommonDefines.h"
#import "AWBookmarkEntry.h"

@interface AWBookmarksWindowController ()
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation AWBookmarksWindowController

+ (void)highlightItem:(AWBookmarkEntry*)item inTextView:(DVTSourceTextView *)textView
{
    // Unfold the source, in case it is currently folded
    [textView unfoldAll:nil];
    
    NSString* text = [textView string];
    NSRange rangeInText = [text rangeOfString:item.lineText];
    if(rangeInText.location != NSNotFound)
    {
        [textView scrollRangeToVisible:rangeInText];
        [textView setSelectedRange:rangeInText];
    }
}

#define MAX_HIGHLIGHT_TRIES 15

+ (void)openItem:(AWBookmarkEntry*)item
{
    if(item)
    {
        
        id<NSApplicationDelegate> appDelegate = (id<NSApplicationDelegate>)[NSApp delegate];
        
        NSString *path = item.fileURL.path;
        
        if (path && [appDelegate application:NSApp openFile:path])
        {
            __block int stopCounter = 0;
            void (^highlightItem)();
            void (^ __block __weak weakHighlightItem) ();
            weakHighlightItem = highlightItem = ^{
                
                if(stopCounter > MAX_HIGHLIGHT_TRIES)
                {
                    return;
                }
                
                stopCounter++;
                
                void(^strongHighlightItem)() = weakHighlightItem;
                
                // Wait a bit while the file actually opens, otherwise what's in the editor before will still be there, not replaced with the file we want to open yet
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    DVTSourceTextView *textView = [IDEHelpers currentSourceTextView];
                    if (textView)
                    {
                        [self highlightItem:item inTextView:textView];
                    }
                    else
                    {
                        // The textView isn't ready, wait a bit and try again
                        strongHighlightItem();
                    }
                });
            };
            highlightItem();
        }
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.window.title = @"Bookmarks";
    
    self.tableView.dataSource = self.bookmarkCollection;
    
    [self.bookmarkCollection addObserver:self forKeyPath:@"count" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    [self.tableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger selectedRow = self.tableView.selectedRow;
    AWBookmarkEntry *entry = [self.bookmarkCollection objectAtIndex:selectedRow];
    
    // Open the file it references and scroll to that line
    [[self class] openItem:entry];
    
    [self.tableView deselectRow:selectedRow];
}

static NSString *identifier = @"AWBookmarksCellIdentifier";

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
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
    
    return textField;
}

@end
