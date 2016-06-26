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
@property NSMutableDictionary<AWBookmarkEntry *, AWBookmarkAnnotation *> *annotationsForEntries;
@property NSMutableArray<AWBookmarkEntry *> *observedEntries;

@end

@implementation AWGutterViewHandler

- (AWGutterViewHandler *)initWithBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection
{
    if(self = [super init])
    {
        self.bookmarkCollection = bookmarkCollection;
        self.annotationsForEntries = [@{} mutableCopy];
        self.observedEntries = [@[] mutableCopy];

        for(int i = 0; i < self.bookmarkCollection.count; i++)
        {
            [self addMarkerForBookmarkEntry:[self.bookmarkCollection objectAtIndex:i]];
        }

        [self swizzleMethodForVisibleAnnotations];
    }
    return self;
}

#pragma GCC diagnostic ignored "-Wundeclared-selector"

- (void)swizzleMethodForVisibleAnnotations
{
    // - (id)visibleAnnotationsForLineNumberRange:(struct _NSRange)arg1;
    NSString *className = @"DVTSourceTextView";
    Class c = NSClassFromString(className);
    NSError *aspectHookError;
    [c aspect_hookSelector:@selector(visibleAnnotationsForLineNumberRange:)
                withOptions:AspectPositionInstead
                 usingBlock:^(id<AspectInfo> info, NSRange range) {

                     NSInvocation *invocation = info.originalInvocation;
                     [invocation invoke];
                     NSArray *annotations;
                     [invocation getReturnValue:&annotations];

                     // Need to retain the annotations so they aren't deallocated before we return
                     CFRetain((__bridge CFTypeRef)(annotations));

                     NSMutableArray *annotationsM = [annotations mutableCopy];
                     CFRetain((__bridge CFTypeRef)(annotationsM));

                     // Find out which of our annotations belongs in this text view (TODO: there's probably a better way of doing this than checking the actual text, ugh)
                     NSTextView *textView = info.instance;
                     NSArray *entries = [self.bookmarkCollection bookmarksInDocumentWithText:textView.string];
                     for(AWBookmarkEntry *entry in entries)
                     {
                         AWBookmarkAnnotation *annotation = self.annotationsForEntries[entry];
                         if(annotation)
                         {
                             [annotationsM addObject:annotation];
                         }
                     }
                     [invocation setReturnValue:&annotationsM];
                     DLOG(@"hey i'm in yr visibleAnnotations");
                 }
                      error:&aspectHookError];
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
    if(![self.annotationsForEntries.allKeys containsObject:entry])
    {
        AWBookmarkAnnotation *annotation = [[AWBookmarkAnnotation alloc] init];
        annotation.location = [[NSClassFromString(@"DVTTextDocumentLocation") alloc] initWithDocumentURL:entry.fileURL timestamp:@([NSDate timeIntervalSinceReferenceDate]) lineRange:NSMakeRange(entry.lineNumber.intValue - 1, 1)];
        self.annotationsForEntries[entry] = annotation;
        annotation.delegate = self;

        [entry addObserver:self forKeyPath:@"toBeDeleted" options:NSKeyValueObservingOptionNew context:nil];
        [entry addObserver:self forKeyPath:@"changed" options:NSKeyValueObservingOptionNew context:nil];
        [self.observedEntries addObject:entry];

        [[IDEHelpers gutterView] setNeedsDisplay:YES];
    }
}

- (void)unobserveEntry:(AWBookmarkEntry *)entry
{
    if([self.observedEntries containsObject:entry])
    {
        // The argument entry is a copy of the entry we are actually observing, so let's get the original from our observedEntries array and unobserve it
        AWBookmarkEntry *observedEntry = [self observedBookmarkEntryForBookmarkEntry:entry];

        [observedEntry removeObserver:self forKeyPath:@"toBeDeleted"];
        [observedEntry removeObserver:self forKeyPath:@"changed"];
        [self.observedEntries removeObject:observedEntry];
    }
}

- (void)deleteMarkerForEntry:(AWBookmarkEntry *)entry
{
    if([self.annotationsForEntries.allKeys containsObject:entry])
    {
        [self unobserveEntry:entry];
        [self.annotationsForEntries removeObjectForKey:entry];
        [[IDEHelpers gutterView] setNeedsDisplay:YES];
    }
}

- (AWBookmarkEntry *)observedBookmarkEntryForBookmarkEntry:(AWBookmarkEntry *)entry
{
    // The argument entry is a copy of the entry we are actually observing, so let's get the original from our observedEntries array
    // (It is equal to, but not the same as, the original)
    return [self.observedEntries objectAtIndex:[self.observedEntries indexOfObject:entry]];
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

        // See if there are any bookmark entries that have been deleted
        NSMutableArray *toDelete = [@[] mutableCopy];
        for(AWBookmarkEntry *entry in self.observedEntries)
        {
            if(![self.bookmarkCollection containsObject:entry])
            {
                [toDelete addObject:entry];
            }
        }
        for(AWBookmarkEntry *entry in toDelete)
        {
            [self unobserveEntry:entry];
            [self deleteMarkerForEntry:entry];
        }
    }
    else if([object isKindOfClass:[AWBookmarkEntry class]])
    {
        AWBookmarkEntry *entry = (AWBookmarkEntry *)object;
        if([self.annotationsForEntries.allKeys containsObject:entry])
        {
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

#pragma DVTTextAnnotationDelegate methods
- (void)didDeleteOrReplaceParagraphForAnnotation:(id)arg1
{
    DLOG(@"bp");
}

- (void)didRemoveAnnotation:(id)arg1
{
    DLOG(@"bp");
    AWBookmarkAnnotation *annotation = (AWBookmarkAnnotation *)arg1;
    AWBookmarkEntry *entry;
    for(AWBookmarkEntry *existingEntry in self.annotationsForEntries.allKeys)
    {
        AWBookmarkAnnotation *existingAnnotation = self.annotationsForEntries[existingEntry];
        if([annotation isEqual:existingAnnotation])
        {
            entry = existingEntry;
            break;
        }
    }

    entry = [self observedBookmarkEntryForBookmarkEntry:entry];

    entry.toBeDeleted = YES;
}

- (void)didMoveAnnotation:(id)arg1
{
    DLOG(@"bp");
}

@end
