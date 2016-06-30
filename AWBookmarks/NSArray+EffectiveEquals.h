//
//  NSArray+EffectiveEquals.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 6/30/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EffectiveProtocol <NSObject>
@required
- (BOOL)isEffectivelyEqual:(id)object;
@end


@interface NSArray (EffectiveEquals)

- (BOOL)effectivelyContainsObject:(id<EffectiveProtocol>)object;
- (NSUInteger)effectiveIndexOfObject:(id<EffectiveProtocol>)object;

@end
