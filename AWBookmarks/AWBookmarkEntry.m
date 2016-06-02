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
@property int lineDistance;
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
        
        
        CGFloat bestScore = NSIntegerMin;
        int bestLine = _lineNumber.intValue;
        for(int lineNo = 0; lineNo < lines.count; lineNo++)
        {
            NSString *line = lines[lineNo];
            NSInteger lineScore = [line levenshteinDistanceFromString:_lineText];
            int lineDistance = abs(_lineNumber.intValue - lineNo);
            CGFloat weightedDistance = 0.1 * lineDistance;
            CGFloat weightedLineScore = lineScore;
            
            AWMatch *match = [[AWMatch alloc] init];
            match.text = line;
            match.score = lineScore;
            match.lineDistance = lineDistance;
            match.lineNo = lineNo;
            match.weightedScore = weightedLineScore;
            [debuggingMatches addObject:match];
            
            if(weightedLineScore > bestScore)
            {
                bestScore = weightedLineScore;
                bestLine = lineNo;
            }
        }
        
        
        [debuggingMatches sortUsingComparator:^NSComparisonResult(AWMatch *obj1, AWMatch *obj2){
            return obj1.weightedScore > obj2.weightedScore;
        }];
        DLOG(@"bp");
        
        self.lineNumber = @(bestLine + 1);
        self.lineText = lines[bestLine];
    }
}
// 54, 53, 55, 52, 56,
// 0, -1, +2, -3, +4
@end
