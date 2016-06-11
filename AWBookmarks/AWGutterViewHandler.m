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
#import "AWBookmarkAnnotation.h"
#import <objc/runtime.h>


@interface AWGutterViewHandler ()
@property (nonatomic) AWBookmarkCollection *bookmarkCollection;
@property NSImage *markerImage;
@property NSMutableSet *observedBookmarkEntries;
@end

@implementation AWGutterViewHandler

- (AWGutterViewHandler *)initWithBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection
{
    if(self = [super init])
    {
        self.bookmarkCollection = bookmarkCollection;
        self.observedBookmarkEntries = [[NSMutableSet alloc] init];
        
        for(int i = 0; i < self.bookmarkCollection.count; i++)
        {
            [self addOrUpdateMarkerForBookmarkEntry:[self.bookmarkCollection objectAtIndex:i]];
        }
        
        NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:@"com.amandawixted.AWBookmarks"];
        NSImage *image = [pluginBundle imageForResource:@"marker-correct-size"];
        self.markerImage = image;
        
        //[self swizzleMethodForDrawLineNumbers];
        [self swizzleMethodForDrawSidebarMarkers];
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
                usingBlock:^(id<AspectInfo> info, CGRect rect, NSUInteger *indexes, NSUInteger count, id a3, id a4, id paraRectBlock) {
                    
                    
                    DVTTextSidebarView *view = info.instance;
                    
                    if(![view isKindOfClass:NSClassFromString(className)]) {
                        [info.originalInvocation invoke];
                    }
                    else
                    {
                        
                        [view lockFocus];
                        {
                            NSURL *url = [[IDEHelpers currentSourceCodeDocument] fileURL];
                            
                            NSArray *bookmarkedLineNumbers = [self.bookmarkCollection lineNumbersForURL:url];
                            if(url && bookmarkedLineNumbers.count > 0)
                            {
                                for (int i = 0; i < count; i++)
                                {
                                    NSUInteger lineNumber = indexes[i];
                                    if([bookmarkedLineNumbers containsObject:@(lineNumber)])
                                    {
                                        NSRect a0, a1;
                                        [view getParagraphRect:&a0 firstLineRect:&a1 forLineNumber:lineNumber];
                                        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"❤️"];
                                        [str drawAtPoint:a0.origin];
                                    }
                                }
                            }
                        }
                        [view unlockFocus];
                    }
                }
                     error:nil];
}

- (void)swizzleMethodForDrawSidebarMarkers
{
    NSString *className = @"DVTTextSidebarView";
    Class c = NSClassFromString(className);
    [c aspect_hookSelector:@selector(_drawSidebarMarkersForAnnotations:atIndexes:textView:getParaRectBlock:)
               withOptions:AspectPositionAfter
                usingBlock:^(id<AspectInfo> info, NSMutableArray *annotations, NSMutableIndexSet *indexes, DVTSourceTextView *textView, id paraRectBlock) {
                    
                    DVTTextSidebarView *view = info.instance;
                    
                    if([view isKindOfClass:NSClassFromString(className)])
                    {
                        
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

- (void)addOrUpdateMarkerForBookmarkEntry:(AWBookmarkEntry *)entry
{
    if(![self.observedBookmarkEntries containsObject:entry])
    {
        [self.observedBookmarkEntries addObject:entry];
        [entry addObserver:self forKeyPath:@"toBeDeleted" options:NSKeyValueObservingOptionNew context:nil];
        [entry addObserver:self forKeyPath:@"changed" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)deleteMarkerForEntry:(AWBookmarkEntry *)entry
{
    if([self.observedBookmarkEntries containsObject:entry])
    {
        [entry removeObserver:self forKeyPath:@"toBeDeleted"];
        [entry removeObserver:self forKeyPath:@"changed"];
        [self.observedBookmarkEntries removeObject:entry];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if(object == self.bookmarkCollection)
    {
        for(int i = 0; i < self.bookmarkCollection.count; i++)
        {
            [self addOrUpdateMarkerForBookmarkEntry:[self.bookmarkCollection objectAtIndex:i]];
        }
    }
    else if([self.observedBookmarkEntries containsObject:object])
    {
        AWBookmarkEntry *entry = (AWBookmarkEntry *)object;
        if([keyPath isEqualToString:@"toBeDeleted"])
        {
            [self deleteMarkerForEntry:entry];
        }
        else if([keyPath isEqualToString:@"changed"])
        {
            [self addOrUpdateMarkerForBookmarkEntry:entry];
        }
    }
}

@end
