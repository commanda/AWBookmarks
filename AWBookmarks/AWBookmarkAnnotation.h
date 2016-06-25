//
//  AWBookmarkAnnotation.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/24/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDEHelpers.h"

@interface AWBookmarkAnnotation : NSObject

@property(retain, nonatomic) NSImage *sidebarMarkerImage;

@property(retain, nonatomic) DVTTextDocumentLocation *location;

@end
