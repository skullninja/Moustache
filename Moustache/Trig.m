//
//  Trig.m
//  Moustache
//
//  Created by Dave Peck on 5/4/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import "Trig.h"

// SOH CAH TOA
@implementation Trig

+ (float)angleDegreesForOpposite:(float)oppositeLength andAdjacent:(float)adjacentLength {
    return RAD_TO_DEG([self angleRadiansForOpposite:oppositeLength andAdjacent:adjacentLength]);
}

+ (float)angleRadiansForOpposite:(float)oppositeLength andAdjacent:(float)adjacentLength {
    if (adjacentLength == 0) return 0;
    return atanf(oppositeLength / adjacentLength);
}

+ (float)angleDegreesForOpposite:(float)oppositeLength andHypotenuse:(float)hypotenuseLength {
    return RAD_TO_DEG([self angleRadiansForOpposite:oppositeLength andHypotenuse:hypotenuseLength]); 
}

+ (float)angleRadiansForOpposite:(float)oppositeLength andHypotenuse:(float)hypotenuseLength {
    if (hypotenuseLength == 0) return 0;
    return asinf(oppositeLength / hypotenuseLength);
}

+ (float)angleDegreesForAdjacent:(float)adjacentLength andHypotenuse:(float)hypotenuseLength {
    return RAD_TO_DEG([self angleRadiansForAdjacent:adjacentLength andHypotenuse:hypotenuseLength]); 
}

+ (float)angleRadiansForAdjacent:(float)adjacentLength andHypotenuse:(float)hypotenuseLength {
    if (hypotenuseLength == 0) return 0;
    return acosf(adjacentLength / hypotenuseLength);
}

+ (float)angleRadiansBetweenFirstPoint:(CGPoint)firstPoint andSecondPoint:(CGPoint)secondPoint {
    return [self angleRadiansForOpposite:(secondPoint.y - firstPoint.y)
                             andAdjacent:(secondPoint.x - firstPoint.x)];
}

+ (float)angleDegreesBetweenFirstPoint:(CGPoint)firstPoint andSecondPoint:(CGPoint)secondPoint {
    return RAD_TO_DEG([self angleRadiansBetweenFirstPoint:firstPoint andSecondPoint:secondPoint]);
}

@end
