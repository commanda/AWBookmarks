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
@property NSMutableDictionary *lineNumbersForBookmarks;
@property NSImage *markerImage;
@end

@implementation AWGutterViewHandler

- (AWGutterViewHandler *)initWithBookmarkCollection:(AWBookmarkCollection *)bookmarkCollection
{
    if(self = [super init])
    {
        self.bookmarkCollection = bookmarkCollection;
        self.lineNumbersForBookmarks = [[NSMutableDictionary alloc] init];
        
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
                            
                            NSUInteger lineNumber = indexes[i];
                            if([[self.lineNumbersForBookmarks allValues] containsObject:@(lineNumber)])
                            {
                                
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

- (void)addOrUpdateMarkerForBookmarkEntry:(AWBookmarkEntry *)entry
{
    if(!self.lineNumbersForBookmarks[entry])
    {
        [entry addObserver:self forKeyPath:@"toBeDeleted" options:NSKeyValueObservingOptionNew context:nil];
        [entry addObserver:self forKeyPath:@"changed" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    self.lineNumbersForBookmarks[entry] = entry.lineNumber;
    
    DLOG(@"bp");
}

- (void)deleteMarkerForEntry:(AWBookmarkEntry *)entry
{
    if(self.lineNumbersForBookmarks[entry])
    {
        [entry removeObserver:self forKeyPath:@"toBeDeleted"];
        [entry removeObserver:self forKeyPath:@"changed"];
        [self.lineNumbersForBookmarks removeObjectForKey:entry];
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
    else if([[self.lineNumbersForBookmarks allKeys] containsObject:object])
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