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

@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, assign) NSUInteger lineNumber;
@property (copy) NSString *lineText;

@end
