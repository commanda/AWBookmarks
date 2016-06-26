//
//  AWGutterViewHandler.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/4/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "IDEHelpers.h"
#import <Foundation/Foundation.h>

@class AWBookmarkEntry;
@class AWBookmarkCollection;

@interface AWGutterViewHandler : NSObject <DVTTextAnnotationDelegate>

- (AWGutterViewHandler *)initWithBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection;

@end
