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

@interface AWGutterViewHandler ()
@property (nonatomic) AWBookmarkCollection *bookmarkCollection;
@property NSMutableDictionary *imagesForBookmarks;
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
    }
    return self;
}

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
