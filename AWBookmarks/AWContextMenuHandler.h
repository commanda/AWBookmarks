//
//  AWContextMenuHandler.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "AWBookmarkCollection.h"

@interface AWContextMenuHandler : NSObject
- (id)initWithBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection;
@end
