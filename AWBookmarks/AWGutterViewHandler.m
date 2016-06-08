//
//  AWGutterViewHandler.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/4/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWGutterViewHandler.h"
#import "IDEHelpers.h"
#import "CommonDefines.h"
#import "AWBookmarkCollection.h"
#import "AWBookmarkEntry.h"
#import "Aspects.h"



@interface AWGutterViewHandler ()
@property (nonatomic) AWBookmarkCollection *bookmarkCollection;
@property NSMutableDictionary *imagesForBookmarks;
@property NSImage *markerImage;
@end

@implementation AWGutterViewHandler

+ (NSImageView *)createMarkerImageView
{
    NSImageView *marker;
    NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:@"com.amandawixted.AWBookmarks"];
    NSImage *image = [pluginBundle imageForResource:@"marker"];
    CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
    marker = [[NSImageView alloc] initWithFrame:frame];
    marker.image = image;
    return marker;
}

- (AWGutterViewHandler *)initWithBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection
{
    if(self = [super init])
    {
        self.bookmarkCollection = bookmarkCollection;
        self.imagesForBookmarks = [[NSMutableDictionary alloc] init];
        
        NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:@"com.amandawixted.AWBookmarks"];
        NSImage *image = [pluginBundle imageForResource:@"marker"];
        self.markerImage = image;
        
        [self swizzleMethodForDrawLineNumbers];
    }
    return self;
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)swizzleMethodForDrawLineNumbers
{
    NSString *className = @"DVTTextSidebarView";
    Class c = NSClassFromString(className);
    [c aspect_hookSelector:@selector(_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)
               withOptions:AspectPositionAfter
     /*
      - (void)_drawLineNumbersInSidebarRect:(struct CGRect)arg1 
      foldedIndexes:(unsigned long long *)arg2 
      count:(unsigned long long)arg3 
      linesToInvert:(id)arg4 
      linesToReplace:(id)arg5 
      getParaRectBlock:(id)arg6;
      
      - (void)_drawSidebarMarkersForAnnotations:(id)arg1 
      atIndexes:(id)arg2 
      textView:(id)arg3 
      getParaRectBlock:(id)arg4;

      */
                usingBlock:^(id<AspectInfo> info, CGRect rect, NSUInteger *indexes, NSUInteger count, id a3, id a4, id paraRectBlock) {
                    
                    
                    DVTTextSidebarView *view = info.instance;
                    
                    if(![view isKindOfClass:NSClassFromString(className)]) {
                        [info.originalInvocation invoke];
                    }
                    else
                    {
                        [view lockFocus];
                        
                        for (int i = 0; i < count; i++)
                        {
                            if(i % 2 == 0)
                            {
                                NSUInteger lineNumber = indexes[i];
                                
                                NSRect a0, a1;
                                [view getParagraphRect:&a0 firstLineRect:&a1 forLineNumber:lineNumber];
                                NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"❤️"];
                                [str drawAtPoint:a0.origin];
                            }
                        }
                        
                        [view unlockFocus];
                        
                        // a recursive call for some reason here...
                    }
                    
                }
                     error:nil];
}
#pragma clang diagnostic pop

- (void)setBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection
{
    [self.bookmarkCollection removeObserver:self forKeyPath:@"count"];
    _bookmarkCollection = bookmarkCollection;
    [self.bookmarkCollection addObserver:self forKeyPath:@"count" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)addMarkerForBookmarkEntry:(AWBookmarkEntry *)entry
{
    NSView *gutterView = [IDEHelpers gutterView];
    
    NSImageView *marker;
    
    if(!self.imagesForBookmarks[entry])
    {
        marker = [[self class] createMarkerImageView];
        
        [gutterView addSubview:marker];
        
        [entry addObserver:self forKeyPath:@"toBeDeleted" options:NSKeyValueObservingOptionNew context:nil];
        [entry addObserver:self forKeyPath:@"changed" options:NSKeyValueObservingOptionNew context:nil];
    }
    else
    {
        marker = self.imagesForBookmarks[entry];
    }
    
    self.imagesForBookmarks[entry] = marker;
    
    // Put the marker on the line we want
    
    DLOG(@"bp");
}

- (void)deleteMarkerForEntry:(AWBookmarkEntry *)entry
{
    NSImageView *marker = self.imagesForBookmarks[entry];
    if(marker)
    {
        [entry removeObserver:self forKeyPath:@"toBeDeleted"];
        [entry removeObserver:self forKeyPath:@"changed"];
        [self.imagesForBookmarks removeObjectForKey:entry];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if(object == self.bookmarkCollection)
    {
        for(int i = 0; i < self.bookmarkCollection.count; i++)
        {
            [self addMarkerForBookmarkEntry:[self.bookmarkCollection objectAtIndex:i]];
        }
    }
    else
    {
        
    }
}

@end
