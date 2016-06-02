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

@property (nonatomic) NSData *fileBookmark;

@end

@implementation AWBookmarkEntry

+ (NSData*)bookmarkForURL:(NSURL*)url
{
    NSError* theError = nil;
    NSData* bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil
                                              error:&theError];
    if (theError || (bookmark == nil))
    {
        // Handle any errors.
        return nil;
    }
    return bookmark;
}

+ (NSURL*)urlForBookmark:(NSData*)bookmark
{
    BOOL bookmarkIsStale = NO;
    NSError* theError = nil;
    NSURL* bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                   options:NSURLBookmarkResolutionWithoutUI
                                             relativeToURL:nil
                                       bookmarkDataIsStale:&bookmarkIsStale
                                                     error:&theError];
    
    if (bookmarkIsStale || (theError != nil))
    {
        // Handle any errors
        return nil;
    }
    return bookmarkURL;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nfilePath: %@\nlineNumber: %@\nlineText:%@", [super description], self.fileURL, self.lineNumber, self.lineText];
}

- (void)setFileBookmark:(NSData *)fileBookmark
{
    _fileBookmark = fileBookmark;
}

- (NSURL *)fileURL
{
    return [AWBookmarkEntry urlForBookmark:self.fileBookmark];
}

- (void)setFileURL:(NSURL *)fileURL
{
    self.fileBookmark = [AWBookmarkEntry bookmarkForURL:fileURL];
    DLOG(@"fileBookmark: %@", [AWBookmarkEntry urlForBookmark:self.fileBookmark]);
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
            self.lineNumber = @(best.lineIndex + 1);
            self.lineText = best.text;
        }
        else
        {
            _toBeDeleted = YES;
        }
    }
}
// 54, 53, 55, 52, 56,
// 0, -1, +2, -3, +4
@end
