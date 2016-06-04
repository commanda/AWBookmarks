//
//  FileWatcher.h
//  GitSync
//
//  Abstract: FileWatcher watches for changes on a set of files and calls fileDidChangeAtPath.
//
//  Created by Peter Sugihara on 1/4/11.
//  Copyright 2011 Peter Sugihara. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OnFileChanged)(NSURL *currentURL);

@interface FileWatcher : NSObject <NSCoding>

+ (FileWatcher *) sharedInstance;

- (void)watchFileAtURL:(NSURL *)path onChanged:(OnFileChanged)onFileChanged;
- (void)stopWatchingFileAtURL:(NSURL *)path;

@end
