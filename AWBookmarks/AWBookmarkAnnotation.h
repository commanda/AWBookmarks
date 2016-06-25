//
//  AWBookmarkAnnotation.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/24/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "IDEHelpers.h"
#import <Foundation/Foundation.h>

@interface AWBookmarkAnnotation : NSObject

@property (retain, nonatomic) NSImage *sidebarMarkerImage;
@property (retain, nonatomic) DVTTextDocumentLocation *location;
@property (readonly) struct _NSRange paragraphRange; // @synthesize paragraphRange=_paragraphRange;

- (struct CGRect)sidebarMarkerRectForFirstLineRect:(struct CGRect)arg1;
- (void)drawSidebarMarkerIconInRect:(struct CGRect)arg1 textView:(id)arg2;

@end
