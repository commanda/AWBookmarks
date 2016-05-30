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

- (void)windowDidLoad {
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
}


+ (void)highlightItem:(AWBookmarkEntry*)item inTextView:(NSTextView*)textView
{
    NSUInteger lineNumber = item.lineNumber.integerValue - 1;
    NSString* text = [textView string];
    
    NSRegularExpression* re =
    [NSRegularExpression regularExpressionWithPattern:@"\n"
                                              options:0
                                                error:nil];
    
    NSArray* result = [re matchesInString:text
                                  options:NSMatchingReportCompletion
                                    range:NSMakeRange(0, text.length)];
    
    if (result.count <= lineNumber) {
        return;
    }
    
    NSUInteger location = 0;
    NSTextCheckingResult* aim = result[lineNumber];
    location = aim.range.location;
    
    NSRange range = [text lineRangeForRange:NSMakeRange(location, 0)];
    
    [textView scrollRangeToVisible:range];
    
    [textView setSelectedRange:range];
}

+ (BOOL)openItem:(AWBookmarkEntry*)item
{
    
    
    IDESourceCodeEditor* editor = [IDEHelpers currentEditor];
    
    id<NSApplicationDelegate> appDelegate = (id<NSApplicationDelegate>)[NSApp delegate];
    
    if ([appDelegate application:NSApp openFile:item.filePath.path])
    {
        if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")])
        {
            NSTextView* textView = editor.textView;
            if (textView)
            {
                
                [self highlightItem:item inTextView:textView];
                
                return YES;
            }
        }
    }

    
    // open the file
    BOOL result = [[NSWorkspace sharedWorkspace] openFile:item.filePath.path withApplication:@"Xcode"];
    
    // open the line
    if (result)
    {
        // Use AppleScript to open it
        NSString* theSource = [NSString stringWithFormat:@"do shell script \"xed --line %ld \" & quoted form of \"%@\"", item.lineNumber.integerValue, item.filePath.absoluteString];
        
        NSAppleScript* theScript = [[NSAppleScript alloc] initWithSource:theSource];
        
        [theScript performSelectorInBackground:@selector(executeAndReturnError:) withObject:nil];
        
        return NO;
    }
    
    return result;
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
