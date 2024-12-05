#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "rapidsnarkC-Bridging-Header.h"
#import "rapidsnark_bridge.h"

FOUNDATION_EXPORT double rapidsnarkVersionNumber;
FOUNDATION_EXPORT const unsigned char rapidsnarkVersionString[];

