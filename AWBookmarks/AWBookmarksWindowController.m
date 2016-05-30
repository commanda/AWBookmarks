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



@end
