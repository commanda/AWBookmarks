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

@implementation AWGutterViewHandler

static AWGutterViewHandler *_instance;

+ (AWGutterViewHandler *)sharedInstance
{
    if(!_instance)
    {
        _instance = [[AWGutterViewHandler alloc] _init];
    }
    return _instance;
}

+ (void)start
{
    [self sharedInstance];
}

- (id)_init
{
    if(self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performBookmarkThisLine:) name:@"AW_contextMenuBookmarkOptionSelected" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)performBookmarkThisLine:(NSNotification *)notif
{
    NSView *gutterView = [IDEHelpers gutterView];
    
    NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:@"com.amandawixted.AWBookmarks"];
    
    NSImage *image = [pluginBundle imageForResource:@"marker.png"];
    CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
    NSImageView *marker = [[NSImageView alloc] initWithFrame:frame];
    marker.image = image;
    [gutterView addSubview:marker];
    
    DLOG(@"bp");
}

@end
