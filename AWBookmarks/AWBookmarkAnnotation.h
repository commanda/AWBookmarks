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
@property (getter=isUserRemovable) BOOL userRemovable;
@property (getter=isUserDraggable) BOOL userDraggable;
@property BOOL wantsInvertedLineNumber;
@property (getter=isVisible) BOOL visible;               // @synthesize visible=_visible;
@property (weak) id<DVTTextAnnotationDelegate> delegate; // @synthesize delegate=_delegate;
@property BOOL wantsDisplayOverLineNumber;
@property BOOL wantsReplaceLineNumber;
@property (readonly) BOOL hideCarets;
@property double precedence;         // @synthesize precedence=_precedence;
@property int annotationStackPolicy; // @synthesize annotationStackPolicy=_annotationStackPolicy;
@property (weak) id representedObject;


- (struct CGRect)sidebarMarkerRectForFirstLineRect:(struct CGRect)arg1;
- (void)drawSidebarMarkerIconInRect:(struct CGRect)arg1 textView:(id)arg2;
- (BOOL)drawsLineHighlight;
- (long long)comparePrecedenceAndLayering:(id)arg1;

@end
