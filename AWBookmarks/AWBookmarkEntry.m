//
//  AWBookmarkEntry.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkEntry.h"
#import "CommonDefines.h"
#import "NSString+LevenshteinDistance.h"
#import "AWBookmarksPlugin.h"

#define THRESHOLD_SCORE 50

@interface AWMatch : NSObject
@property NSString *text;
@property CGFloat score;
@property NSInteger lineDistance;
@property int lineIndex;
@property CGFloat weightedScore;
@end

@implementation AWMatch

- (NSString *)description
{
    return [NSString stringWithFormat:@"\ntext: %@\nscore: %f\ndistance: %ld\nlineNumber: %d\nWEIGHTEDSCORE: %f\n", self.text, self.score, self.lineDistance, self.lineIndex, self.weightedScore];
}
@end


@interface AWBookmarkEntry ()

@end

@implementation AWBookmarkEntry

- (id)initWithCoder:(NSCoder *)decoder
{
    if(self = [super init])
    {
        self.fileURL = [decoder decodeObjectForKey:@"fileURL"];
        self.lineNumber = [decoder decodeObjectForKey:@"lineNumber"];
        self.lineText = [decoder decodeObjectForKey:@"lineText"];
        self.uuid = [decoder decodeObjectForKey:@"uuid"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.fileURL forKey:@"fileURL"];
    [encoder encodeObject:self.lineNumber forKey:@"lineNumber"];
    [encoder encodeObject:self.lineText forKey:@"lineText"];
    [encoder encodeObject:self.uuid forKey:@"uuid"];
}

- (id)copyWithZone:(NSZone *)zone
{
    AWBookmarkEntry *newEntry = [[self class] allocWithZone:zone];
    newEntry->_fileURL = self.fileURL;
    newEntry->_lineText = self.lineText;
    newEntry->_lineNumber = self.lineNumber;
    newEntry->_uuid = self.uuid;
    return newEntry;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nfilePath: %@\nlineNumber: %@\nlineText:%@", [super description], self.fileURL, self.lineNumber, self.lineText];
}

- (NSString *)uuid
{
    if(!_uuid)
    {
        _uuid = [[NSUUID UUID] UUIDString];
    }
    return _uuid;
}

- (void)setFileURL:(NSURL *)fileURL
{
    [[FileWatcher sharedInstance] stopWatchingFileAtURL:_fileURL];
    
    [self willChangeValueForKey:@"changed"];
    _fileURL = fileURL;
    [self didChangeValueForKey:@"changed"];
    
    __weak AWBookmarkEntry *weakSelf = self;
    [[FileWatcher sharedInstance] watchFileAtURL:fileURL onChanged:^(NSURL *currentURL){
        DLOG(@"hey the file changed %@", currentURL);
        AWBookmarkEntry *strongSelf = weakSelf;
        [strongSelf willChangeValueForKey:@"changed"];
        strongSelf->_fileURL = currentURL;
        [strongSelf didChangeValueForKey:@"changed"];
    }];
}

- (void)resolve
{
    /*
     search through the file fuzzy matching for that old line text
     there will probably be several lines that are exactly the same, so then weight them by distance from the original line number
     have some threshold, so if we don't get a good enough match, delete that bookmark entry
     use edit distance algorithm, use fuzzy matching algorithm
     */
    NSError *error;
    NSString *text = [NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:&error];
    
    if(!error)
    {
        // If our document is currently open, it might be different from the saved version on disk because the user is editing it and might not have saved
        
        NSURL *openURL = [[IDEHelpers currentSourceCodeDocument] fileURL];
        if([openURL isEqual:self.fileURL])
        {
            // Use the text from the open document instead of the text on disk
            text = [IDEHelpers currentSourceTextView].string;
        }
        
        NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSMutableArray *lineEvaluations = [[NSMutableArray alloc] init];
        
        int myLineIndex = _lineNumber.intValue - 1;
        
        for(int lineIndex = 0; lineIndex < lines.count; lineIndex++)
        {
            NSString *line = lines[lineIndex];
            NSInteger lineScore = [line levenshteinDistanceFromString:_lineText];
            NSInteger lineDistance = abs(myLineIndex - lineIndex);
            
            AWMatch *match = [[AWMatch alloc] init];
            match.text = line;
            match.score = lineScore;
            match.lineDistance = lineDistance;
            match.lineIndex = lineIndex;
            [lineEvaluations addObject:match];
        }
        
        [lineEvaluations sortUsingComparator:^NSComparisonResult(AWMatch *obj1, AWMatch *obj2){
            if(obj1.score == obj2.score)
            {
                return obj1.lineDistance > obj2.lineDistance;
            }
            else return obj1.score > obj2.score;
        }];
        
        AWMatch *best = [lineEvaluations firstObject];
        
        if(best.score < THRESHOLD_SCORE && best.text.length > 0)
        {
            [self willChangeValueForKey:@"changed"];
            self.lineNumber = @(best.lineIndex + 1);
            self.lineText = best.text;
            [self didChangeValueForKey:@"changed"];
        }
        else
        {
            [self willChangeValueForKey:@"toBeDeleted"];
            _toBeDeleted = YES;
            [self didChangeValueForKey:@"toBeDeleted"];
        }
    }
}

#pragma FileWatcherDelegate method
- (void)fileDidChangeAtURL:(NSURL *)notification;
{
    [self resolve];
}

@end
