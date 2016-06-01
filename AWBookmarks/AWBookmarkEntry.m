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
        CGFloat bestScore = NSIntegerMin;
        int bestLine = _lineNumber.intValue;
        for(int lineNo = 0; lineNo < lines.count; lineNo++)
        {
            NSString *line = lines[lineNo];
            CGFloat lineScore = [line scoreAgainst:_lineText fuzziness:@(0.5)];
            //lineScore *= abs(_lineNumber.intValue - lineNo);
            
            if(lineScore > bestScore)
            {
                bestScore = lineScore;
                bestLine = lineNo;
            }
        }
        
        self.lineNumber = @(bestLine);
        self.lineText = lines[bestLine];
    }
}
// 54, 53, 55, 52, 56,
// 0, -1, +2, -3, +4
@end
