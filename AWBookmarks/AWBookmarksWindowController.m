//
//  AWBookmarksWindowController.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarksWindowController.h"

@interface AWBookmarksWindowController ()
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation AWBookmarksWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.title = @"Bookmarks";
    
    self.tableView.dataSource = self.bookmarkCollection;
}

static NSString *identifier = @"AWBookmarksIdentifier";

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
    if(!textField)
    {
        textField = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, tableColumn.width, 100)];
        textField.identifier = identifier;
    }
    
    return textField;
}

@end
