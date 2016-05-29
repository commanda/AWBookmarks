//
//  AWBookmarkEntry.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkEntry.h"

@implementation AWBookmarkEntry

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nfilePath: %@\nlineNumber: %@\nlineText:%@", [super description], self.filePath, self.lineNumber, self.lineText];
}

@end
