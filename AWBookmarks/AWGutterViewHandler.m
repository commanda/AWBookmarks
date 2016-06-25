//
//  AWGutterViewHandler.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/4/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWGutterViewHandler.h"
#import "AWBookmarkAnnotation.h"
#import "AWBookmarkCollection.h"
#import "AWBookmarkEntry.h"
#import "Aspects.h"
#import "CommonDefines.h"
#import "IDEHelpers.h"
#import <objc/runtime.h>


@interface AWGutterViewHandler ()
@property (nonatomic) AWBookmarkCollection *bookmarkCollection;
@property NSMutableDictionary<UUID *, AWBookmarkAnnotation *> *observedBookmarkEntries;

@end

@implementation AWGutterViewHandler

- (AWGutterViewHandler *)initWithBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection
{
    if(self = [super init])
    {
        self.bookmarkCollection = bookmarkCollection;
        self.observedBookmarkEntries = [@{} mutableCopy];

        for(int i = 0; i < self.bookmarkCollection.count; i++)
        {
            [self addMarkerForBookmarkEntry:[self.bookmarkCollection objectAtIndex:i]];
        }

        [self swizzleMethodForDrawLineNumbers];
        [self swizzleMethodForDrawAnnotations];
    }
    return self;
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)swizzleMethodForDrawAnnotations
{
    //- (void)_drawSidebarMarkersForAnnotations:(id)arg1 atIndexes:(id)arg2 textView:(id)arg3 getParaRectBlock:(id)arg4;
    NSString *className = @"DVTTextSidebarView";
    Class c = NSClassFromString(className);
    NSError *aspectHookError;
    [c aspect_hookSelector:@selector(_drawSidebarMarkersForAnnotations:atIndexes:textView:getParaRectBlock:)
                withOptions:AspectPositionBefore
                 usingBlock:^(id<AspectInfo> info, NSMutableArray *annotations, NSMutableIndexSet *indexSet, DVTSourceTextView *textView, id paraRectBlock) {
                     

                     NSURL *url = [[IDEHelpers currentSourceCodeDocument] fileURL];
                     NSArray<AWBookmarkEntry *> *entries = [self.bookmarkCollection bookmarksForURL:url];

                     for(AWBookmarkEntry *entry in entries)
                     {
                         AWBookmarkAnnotation *annotation = self.observedBookmarkEntries[entry.uuid];
                         if(annotation)
                         {
                             [annotations addObject:annotation];
                             [indexSet addIndex:annotations.count - 1];
                         }
                     }
                     DLOG(@"hey i'm in yr drawSidebar");
                 }
                      error:&aspectHookError];


    [c aspect_hookSelector:@selector(_drawSidebarMarkersForAnnotations:atIndexes:textView:getParaRectBlock:)
                withOptions:AspectPositionAfter
                 usingBlock:^(id<AspectInfo> info, NSMutableArray *annotations, NSMutableIndexSet *indexSet, NSTextView *textView, id paraRectBlock) {
                     DLOG(@"hey i'm in yr drawSidebar");

                 }
                      error:&aspectHookError];
}

- (void)swizzleMethodForDrawLineNumbers
{
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName : [NSColor whiteColor],
        NSFontAttributeName : [NSFont fontWithName:@"Xcode Digits" size:10],
    };

    NSString *className = @"DVTTextSidebarView";
    Class c = NSClassFromString(className);
    [c aspect_hookSelector:@selector(_drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:)
                withOptions:AspectPositionAfter
                 usingBlock:^(id<AspectInfo> info, CGRect rect, NSUInteger *indexes, NSUInteger count, id a3, id a4, id paraRectBlock) {


                     DVTTextSidebarView *view = info.instance;

                     if(![view isKindOfClass:NSClassFromString(className)])
                     {
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
                                 for(int i = 0; i < count - 1; i++)
                                 {
                                     NSUInteger lineNumber = indexes[i];
                                     NSUInteger nextLineNumber = indexes[i + 1];
                                     NSRange foldedRange = NSMakeRange(lineNumber, nextLineNumber - lineNumber);

                                     for(NSUInteger j = foldedRange.location; j < NSMaxRange(foldedRange); j++)
                                     {
                                         if([bookmarkedLineNumbers containsObject:@(j)])
                                         {
                                             NSRect a0, a1;
                                             [view getParagraphRect:&a0 firstLineRect:&a1 forLineNumber:lineNumber];

                                             NSAttributedString *str = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu", (unsigned long)lineNumber]
                                                                                                       attributes:attributes];


                                             [str drawInRect:a1];
                                         }
                                     }
                                 }
                             }
                         }
                         [view unlockFocus];
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
    if(![self.observedBookmarkEntries.allKeys containsObject:entry.uuid])
    {
        AWBookmarkAnnotation *annotation = [[AWBookmarkAnnotation alloc] init];
        annotation.location = [[NSClassFromString(@"DVTTextDocumentLocation") alloc] initWithDocumentURL:entry.fileURL timestamp:@([NSDate timeIntervalSinceReferenceDate]) lineRange:NSMakeRange(entry.lineNumber.intValue - 1, 1)];
        self.observedBookmarkEntries[entry.uuid] = annotation;
        [entry addObserver:self forKeyPath:@"toBeDeleted" options:NSKeyValueObservingOptionNew context:nil];
        [entry addObserver:self forKeyPath:@"changed" options:NSKeyValueObservingOptionNew context:nil];

        [[IDEHelpers gutterView] setNeedsDisplay:YES];
    }
}

- (void)deleteMarkerForEntry:(AWBookmarkEntry *)entry
{
    if([self.observedBookmarkEntries.allKeys containsObject:entry.uuid])
    {
        [entry removeObserver:self forKeyPath:@"toBeDeleted"];
        [entry removeObserver:self forKeyPath:@"changed"];
        [self.observedBookmarkEntries removeObjectForKey:entry.uuid];

        [[IDEHelpers gutterView] setNeedsDisplay:YES];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context
{
    if(object == self.bookmarkCollection)
    {
        // See if there are any new bookmarks
        for(int i = 0; i < self.bookmarkCollection.count; i++)
        {
            [self addMarkerForBookmarkEntry:[self.bookmarkCollection objectAtIndex:i]];
        }

        // See if there are any bookmarks that have been deleted
        NSMutableArray *toDelete = [@[] mutableCopy];
        for(UUID *entry in self.observedBookmarkEntries)
        {
            if(![self.bookmarkCollection containsObjectWithUUID:entry])
            {
                [toDelete addObject:entry];
            }
        }

        for(AWBookmarkEntry *entry in toDelete)
        {
            [self deleteMarkerForEntry:entry];
        }
    }
    else if([object isKindOfClass:[AWBookmarkEntry class]])
    {
        AWBookmarkEntry *entry = (AWBookmarkEntry *)object;
        if([self.observedBookmarkEntries.allKeys containsObject:entry.uuid])
        {
            AWBookmarkEntry *entry = (AWBookmarkEntry *)object;
            if([keyPath isEqualToString:@"toBeDeleted"])
            {
                [self deleteMarkerForEntry:entry];
            }
            else if([keyPath isEqualToString:@"changed"])
            {
                [self addMarkerForBookmarkEntry:entry];
            }
        }
    }
}

@end
