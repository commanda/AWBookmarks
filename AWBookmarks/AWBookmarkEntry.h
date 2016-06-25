//
//  AWBookmarkEntry.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "FileWatcher.h"
#import "IDEHelpers.h"
#import <Foundation/Foundation.h>

@interface AWBookmarkEntry : NSObject <NSCoding, NSCopying>

@property (nonatomic) NSURL *fileURL;
@property NSURL *containingProjectURL;
@property (nonatomic, assign) NSNumber *lineNumber;
@property (nonatomic, copy) NSString *lineText;
@property BOOL toBeDeleted;
@property (readonly) BOOL changed;
@property (nonatomic) NSString *uuid;

- (void)resolve;
- (void)highlightInTextView:(DVTSourceTextView *)textView;

@end
