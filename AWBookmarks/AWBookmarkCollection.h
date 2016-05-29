//
//  AWBookmarkCollection.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/21/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWBookmarkCollection : NSObject


@property (strong) NSMutableArray *bookmarks;

- (void)saveBookmarks;

@end
