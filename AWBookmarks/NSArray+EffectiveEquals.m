//
//  NSArray+EffectiveEquals.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/30/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "NSArray+EffectiveEquals.h"

@implementation NSArray (EffectiveEquals)


- (BOOL)effectivelyContainsObject:(id<EffectiveProtocol>)object
{
    return [self effectiveIndexOfObject:object] != NSNotFound;
}

- (NSUInteger)effectiveIndexOfObject:(id<EffectiveProtocol>)object
{
    __block NSUInteger indexToReturn = NSNotFound;
    if([[object class] conformsToProtocol:@protocol(EffectiveProtocol)])
    {
        id<EffectiveProtocol> epObject = object;
        [self enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if([epObject isEffectivelyEqual:obj])
            {
                indexToReturn = idx;
                *stop = YES;
            }
        }];
    }
    return indexToReturn;
}

@end
