//
//  NSString+LevenshteinDistance.h
//  StringScoreProject
//
//  Created by Amanda Wixted on 6/2/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LevenshteinDistance)

- (NSInteger)levenshteinDistanceFromString:(NSString *)comparisonString;

@end
