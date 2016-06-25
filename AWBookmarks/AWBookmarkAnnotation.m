//
//  AWBookmarkAnnotation.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/24/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkAnnotation.h"
#import "CommonDefines.h"

@implementation AWBookmarkAnnotation

- (id)init
{
    if(self = [super init])
    {
        NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:@"com.amandawixted.AWBookmarks"];
        NSImage *image = [pluginBundle imageForResource:@"marker-correct-size"];
        self.sidebarMarkerImage = image;
        self.wantsInvertedLineNumber = YES;
        self.userDraggable = YES;
        self.userRemovable = YES;
        self.visible = YES;
        self.wantsDisplayOverLineNumber = NO;
        self.wantsReplaceLineNumber = NO;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: line: %lld", [super description], self.location.startingLineNumber];
}

- (NSRange)paragraphRange
{
    return NSMakeRange(self.location.startingLineNumber, 1);
}

- (struct CGRect)sidebarMarkerRectForFirstLineRect:(struct CGRect)arg1
{
    return CGRectMake(arg1.origin.x, arg1.origin.y, self.sidebarMarkerImage.size.width, self.sidebarMarkerImage.size.height);
}

- (void)drawSidebarMarkerIconInRect:(struct CGRect)arg1 textView:(id)arg2
{
    [self.sidebarMarkerImage drawInRect:arg1];
}

- (BOOL)drawsLineHighlight;
{
    // TODO: maybe we do want to draw line highlight?
    return NO;
}

- (BOOL)drawsHighlightedRanges
{
    return NO;
}

@end
