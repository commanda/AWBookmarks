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
    return arg1;
}

- (void)drawSidebarMarkerIconInRect:(struct CGRect)arg1 textView:(id)arg2
{
    [self.sidebarMarkerImage drawInRect:arg1];
}

@end
