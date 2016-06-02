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


@implementation AWBookmarkEntry

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nfilePath: %@\nlineNumber: %@\nlineText:%@", [super description], self.filePath, self.lineNumber, self.lineText];
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
    NSString *text = [NSString stringWithContentsOfURL:self.filePath encoding:NSUTF8StringEncoding error:&error];
    if(!error)
    {
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
