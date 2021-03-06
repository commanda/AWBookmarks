//
//  CommonDefines.h
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/19/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#ifndef CommonDefines_h
#define CommonDefines_h


#import <AppKit/AppKit.h>

#if DEBUG
#define DLOG(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#define DLOG(fmt, ...) ;
#endif


#endif /* CommonDefines_h */
