//
//  FileWatcher.m
//  GitSync
//
//  Created by Peter Sugihara on 1/4/11.
//  Copyright 2011 Peter Sugihara. All rights reserved.
//

#import "FileWatcher.h"


@interface WatchedFile : NSObject
@property (strong) NSURL *watchedURL;
@property (strong) NSDate *modDate;
@property (copy) OnFileChanged onFileChanged;
@end

@implementation WatchedFile

- (BOOL)isEqual:(id)object
{
    BOOL toReturn = NO;
    if([object isKindOfClass:[WatchedFile class]])
    {
        WatchedFile *other = (WatchedFile *)object;
        if([other.modDate compare:self.modDate] == NSOrderedSame && [other.watchedURL isEqual:self.watchedURL])
        {
            toReturn = YES;
        }
    }
    return toReturn;
}
@end


@interface FileWatcher ()
- (void)startWatching;
- (void)checkForUpdates;
- (NSDate *)modificationDateForURL:(NSURL *)url;
- (NSURL *)urlFromBookmark:(NSData *)bookmark;
@property (nonatomic, strong) NSMutableDictionary *fileModificationDates;
@property NSRunLoop *runLoop;
@property NSFileManager *fm;
@property BOOL isWatching;

@end


@implementation FileWatcher

static FileWatcher *instance;

+ (FileWatcher *)sharedInstance
{
    if(!instance)
    {
        instance = [[FileWatcher alloc] _init];
    }
    return instance;
}

- (id)_init
{
    if((self = [super init]))
    {
        self.fm = [[NSFileManager alloc] init];
        self.fileModificationDates = [[NSMutableDictionary alloc] init];
        [self startWatching];
    }

    return self;
}

- (void)watchFileAtURL:(NSURL *)url onChanged:(OnFileChanged)onFileChanged
{
    NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                     includingResourceValuesForKeys:NULL
                                      relativeToURL:NULL
                                              error:NULL];
    NSDate *modDate = [self modificationDateForURL:url];
    WatchedFile *wf = [[WatchedFile alloc] init];
    wf.watchedURL = url;
    wf.modDate = modDate;
    wf.onFileChanged = onFileChanged;

    self.fileModificationDates[bookmark] = wf;
}

- (void)stopWatchingFileAtURL:(NSURL *)url
{
    // TODO: make sure this works? i thought the keys were bookmark urls, are they the same as file urls?
    if(url)
    {
        [self.fileModificationDates removeObjectForKey:url];
    }
}

- (NSDate *)modificationDateForURL:(NSURL *)URL
{
    NSDictionary *fileAttributes = [self.fm attributesOfItemAtPath:[URL path] error:NULL];
    NSDate *modDate = [fileAttributes fileModificationDate];
    return modDate;
}

- (void)startWatching
{
    if(!self.isWatching)
    {
        self.isWatching = YES;
        float latency = .5;
        NSTimer *timer = [NSTimer timerWithTimeInterval:latency
                                                 target:self
                                               selector:@selector(checkForUpdates)
                                               userInfo:nil
                                                repeats:YES];
        self.runLoop = [NSRunLoop currentRunLoop];
        [self.runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)checkForUpdates
{
    for(NSData *bookmark in [self.fileModificationDates allKeys])
    {
        NSURL *watchedURL = [self urlFromBookmark:bookmark];
        NSDate *modDate = [self modificationDateForURL:watchedURL];
        WatchedFile *temp = [[WatchedFile alloc] init];
        temp.watchedURL = watchedURL;
        temp.modDate = modDate;

        WatchedFile *existing = self.fileModificationDates[bookmark];

        if(![existing isEqual:temp])
        {
            self.fileModificationDates[bookmark] = temp;
            existing.onFileChanged(watchedURL);
            temp.onFileChanged = existing.onFileChanged;


            [self.fileModificationDates removeObjectForKey:bookmark];
            // Rewatch the file at the current URL in case the file is overwritten.
            if(watchedURL)
            {
                [self watchFileAtURL:watchedURL onChanged:existing.onFileChanged];
            }
        }
    }
}

- (NSURL *)urlFromBookmark:(NSData *)bookmark
{
    NSError *error = noErr;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark
                                           options:NSURLBookmarkResolutionWithoutUI
                                     relativeToURL:NULL
                               bookmarkDataIsStale:NULL
                                             error:&error];
    if(error != noErr)
        NSLog(@"%@", [error description]);
    return url;
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if((self = [self init]))
    {
        self.fileModificationDates = [decoder decodeObjectForKey:@"fileModificationDates"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.fileModificationDates forKey:@"fileModificationDates"];
}

@end
