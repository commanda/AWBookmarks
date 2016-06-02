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

@interface AWMatch : NSObject
@property NSString *text;
@property CGFloat score;
@property NSInteger lineDistance;
@property int lineNo;
@property CGFloat weightedScore;
@end

@implementation AWMatch
- (NSString *)description
{
    return [NSString stringWithFormat:@"\ntext: %@\nscore: %f\ndistance: %d\nlineNo: %d\nWEIGHTEDSCORE: %f\n", self.text, self.score, self.lineDistance, self.lineNo, self.weightedScore];
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
     there will probalby be several lines that are exactly the same, so then weight them by distance from the original line number
     have some threshold, so if we don't get a good enough match, delete that bookmark entry
     use edit distance algorithm, use fuzzy matching algorithm
     */
    DLOG(@"----------------------\n%@", self.lineText);
    NSError *error;
    NSString *text = [NSString stringWithContentsOfURL:self.filePath encoding:NSUTF8StringEncoding error:&error];
    if(!error)
    {
        NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSMutableArray *debuggingMatches = [[NSMutableArray alloc] init];
        
        int myLineIndex = _lineNumber.intValue - 1;
        
        CGFloat bestScore = NSIntegerMax;
        int bestLineIndex = 0;
        for(int lineIndex = 0; lineIndex < lines.count; lineIndex++)
        {
            NSString *line = lines[lineIndex];
            NSInteger lineScore = [line levenshteinDistanceFromString:_lineText];
            NSInteger lineDistance = abs(myLineIndex - lineIndex);
            NSInteger weightedLineScore = (lineScore + 1) * lineDistance;
            
            AWMatch *match = [[AWMatch alloc] init];
            match.text = line;
            match.score = lineScore;
            match.lineDistance = lineDistance;
            match.lineNo = lineIndex;
            match.weightedScore = weightedLineScore;
            [debuggingMatches addObject:match];
            
            if(weightedLineScore < bestScore)
            {
                bestScore = weightedLineScore;
                bestLineIndex = lineIndex;
            }
            DLOG(@"bp");
        }
        
        
        [debuggingMatches sortUsingComparator:^NSComparisonResult(AWMatch *obj1, AWMatch *obj2){
            return obj1.weightedScore > obj2.weightedScore;
        }];
        DLOG(@"bp");
        
        self.lineNumber = @(bestLineIndex + 1);
        self.lineText = lines[bestLineIndex];
    }
}
// 54, 53, 55, 52, 56,
// 0, -1, +2, -3, +4
@end
