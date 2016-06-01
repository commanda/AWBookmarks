//
//  AWBookmarkEntry.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkEntry.h"
#import "NSString+Score.h"
#import "CommonDefines.h"

@interface AWMatch : NSObject
@property NSString *text;
@property CGFloat score;
@property int distance;
@property int lineNo;
@property CGFloat weightedScore;
@end

@implementation AWMatch
- (NSString *)description
{
    return [NSString stringWithFormat:@"\ntext: %@\nscore: %f\ndistance: %d\nlineNo: %d\nWEIGHTEDSCORE: %f\n", self.text, self.score, self.distance, self.lineNo, self.weightedScore];
}
@end


@implementation AWBookmarkEntry

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nfilePath: %@\nlineNumber: %@\nlineText:%@", [super description], self.filePath, self.lineNumber, self.lineText];
}

- (void)resolve
{
    
    NSString *testString = @"Hello world!";
    
    NSLog(@"%f", [@"Hello world!" scoreAgainst:@"Hello world!"]);
    NSLog(@"%f", [@"Hello world!" scoreAgainst:@"Hello sdfworld!"]);
    NSLog(@"%f", [@"Hello sdfworld!" scoreAgainst:@"Hello world!"]);
    
    
    NSLog(@"%f", [@"Hello world!" scoreAgainst:@"Hello sdfworld!" fuzziness:nil options:NSStringScoreOptionFavorSmallerWords]);
    NSLog(@"%f", [@"Hello sdfworld!" scoreAgainst:@"Hello world!" fuzziness:nil options:NSStringScoreOptionFavorSmallerWords]);
    
    NSLog(@"%f", [@"Hello world!" scoreAgainst:@"Hello sdfworld!" fuzziness:nil options:NSStringScoreOptionReducedLongStringPenalty]);
    NSLog(@"%f", [@"Hello sdfworld!" scoreAgainst:@"Hello world!" fuzziness:nil options:NSStringScoreOptionReducedLongStringPenalty]);
    
    CGFloat result1 = [testString scoreAgainst:@"Hello world!"];
    CGFloat result2 = [testString scoreAgainst:@"world"];
    CGFloat result3 = [testString scoreAgainst:@"wXrld" fuzziness:[NSNumber numberWithFloat:0.8]];
    CGFloat result4 = [testString scoreAgainst:@"world" fuzziness:nil options:NSStringScoreOptionFavorSmallerWords];
    CGFloat result5 = [testString scoreAgainst:@"world" fuzziness:nil options:(NSStringScoreOptionFavorSmallerWords | NSStringScoreOptionReducedLongStringPenalty)];
    CGFloat result6 = [testString scoreAgainst:@"HW"]; // abbreviation matching example
    
    NSLog(@"Result 1 = %f", result1);
    NSLog(@"Result 2 = %f", result2);
    NSLog(@"Result 3 = %f", result3);
    NSLog(@"Result 4 = %f", result4);
    NSLog(@"Result 5 = %f", result5);
    NSLog(@"Result 6 = %f", result6);
    
    
    
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
            CGFloat lineScore = [line scoreAgainst:_lineText fuzziness:@(0.5)];
            int distance = abs(_lineNumber.intValue - lineNo);
            CGFloat weightedDistance = 0.1 * distance;
            CGFloat weightedLineScore = lineScore;
            
            AWMatch *match = [[AWMatch alloc] init];
            match.text = line;
            match.score = lineScore;
            match.distance = distance;
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
