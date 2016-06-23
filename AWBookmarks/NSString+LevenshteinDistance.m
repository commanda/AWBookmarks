//
//  NSString+LevenshteinDistance.m
//  StringScoreProject
//
//  Created by Amanda Wixted on 6/2/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "NSString+LevenshteinDistance.h"

@implementation NSString (LevenshteinDistance)

- (NSInteger)levenshteinDistanceFromString:(NSString *)comparisonString
{
    // Remove whitespace from both strings
    NSString *originalString = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    comparisonString = [comparisonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    originalString = [originalString lowercaseString];
    comparisonString = [comparisonString lowercaseString];

    // Step 1 (Steps follow description at http://www.merriampark.com/ld.htm)
    NSInteger k, i, j, cost, *d, distance;

    NSInteger lenOriginal = [originalString length];
    NSInteger lenComparison = [comparisonString length];

    // If they're both empty, they are the same; zero edit distance
    if(lenOriginal == 0 && lenComparison == 0)
    {
        return 0;
    }

    // If one is empty and the other one isn't, they are not the same, and their edit distance is the length of the larger one
    if((lenOriginal == 0 && lenComparison > 0) || (lenComparison == 0 && lenOriginal > 0))
    {
        return MAX(lenOriginal, lenComparison);
    }


    d = malloc(sizeof(NSInteger) * lenComparison * lenOriginal);

    // Step 2
    for(k = 0; k < lenOriginal; k++)
        d[k] = k;

    for(k = 0; k < lenComparison; k++)
        d[k * lenOriginal] = k;

    // Step 3 and 4
    for(i = 1; i < lenOriginal; i++)
        for(j = 1; j < lenComparison; j++)
        {

            // Step 5
            if([originalString characterAtIndex:i - 1] ==
               [comparisonString characterAtIndex:j - 1])
                cost = 0;
            else
                cost = 1;

            // Step 6
            d[j * lenOriginal + i] = MIN(MIN(d[(j - 1) * lenOriginal + i] + 1, d[j * lenOriginal + i - 1] + 1), d[(j - 1) * lenOriginal + i - 1] + cost);

            // This conditional adds Damerau transposition to Levenshtein distance
            if(i > 1 && j > 1 && [originalString characterAtIndex:i - 1] == [comparisonString characterAtIndex:j - 2] &&
               [originalString characterAtIndex:i - 2] == [comparisonString characterAtIndex:j - 1])
            {
                d[j * lenOriginal + i] = MIN(d[j * lenOriginal + i], d[(j - 2) * lenOriginal + i - 2] + cost);
            }
        }

    distance = d[lenOriginal * lenComparison - 1];

    free(d);

    return distance;
}

@end
