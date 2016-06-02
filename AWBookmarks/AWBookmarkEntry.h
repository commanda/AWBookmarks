//
//  AWBookmarkEntry.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDEHelpers.h"

@interface AWBookmarkEntry : NSObject

@property (nonatomic, copy) NSURL *fileURL;
@property (nonatomic, assign) NSNumber *lineNumber;
@property (copy) NSString *lineText;
@property (readonly) BOOL toBeDeleted;

- (void)resolve;

@end
