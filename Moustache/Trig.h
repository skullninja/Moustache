//
//  Trig.h
//  Moustache
//
//  Created by Dave Peck on 5/4/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEG_TO_RAD(d) d * M_PI / 180
#define RAD_TO_DEG(r) (r * (180 / M_PI))

@interface Trig : NSObject

+ (float)angleDegreesForOpposite:(float)oppositeLength andAdjacent:(float)adjacentLength;

+ (float)angleRadiansForOpposite:(float)oppositeLength andAdjacent:(float)adjacentLength;

+ (float)angleDegreesForOpposite:(float)oppositeLength andHypotenuse:(float)hypotenuseLength;

+ (float)angleRadiansForOpposite:(float)oppositeLength andHypotenuse:(float)hypotenuseLength;

+ (float)angleDegreesForAdjacent:(float)adjacentLength andHypotenuse:(float)hypotenuseLength;

+ (float)angleRadiansForAdjacent:(float)adjacentLength andHypotenuse:(float)hypotenuseLength;

+ (float)angleRadiansBetweenFirstPoint:(CGPoint)firstPoint andSecondPoint:(CGPoint)secondPoint;

+ (float)angleDegreesBetweenFirstPoint:(CGPoint)firstPoint andSecondPoint:(CGPoint)secondPoint;

@end
