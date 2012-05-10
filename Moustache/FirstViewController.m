//
//  FirstViewController.m
//  Moustache
//
//  Created by Dave Peck on 4/26/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import "FirstViewController.h"
#import <CoreImage/CoreImage.h>
#import "Trig.h"

@interface FirstViewController ()

@end

@implementation FirstViewController
@synthesize stacheImage = _stacheImage;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _faceQueue = dispatch_queue_create("faceQueue", NULL); 
    
    _tryCount = 0;
    _processFrame = NO;
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setStacheImage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setCamera:self.camera == 1 ? 0 : 1];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

+ (CIImage *)imageWithImage:(CIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    UIImage *drawImage = [UIImage imageWithCIImage:image];
    [drawImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return [CIImage imageWithCGImage:newImage.CGImage];
}

/*
+ (CIImage *)scaleCIImage:(CIImage *)originalImage scale:(float) scale {
    
    NSArray *list = [CIFilter filterNamesInCategory:kCICategoryBuiltIn];
	
	CIFilter *scaleImage  = [CIFilter filterWithName: @"CILanczosScaleTransform"			// create a filter instance
										keysAndValues: @"inputImage", originalImage, @"inputAspectRatio", [NSNumber numberWithFloat:1.0], nil];
	[scaleImage setDefaults];
	[scaleImage setValue:[NSNumber numberWithFloat: scale] forKey: @"inputScale"];			// set some values to my filter
    
    return [scaleImage outputImage];
}
 
 */

- (void)processCameraImage:(CIImage *)image {
    
    if (!_processFrame) {
        _processFrame = YES;
        return;
    }
    
    image = [FirstViewController imageWithImage:image scaledToSize:CGSizeMake(160, 240)];    
    dispatch_async(_faceQueue, ^{
        
        NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
        
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        
        CGAffineTransform t;
        
        if (orientation == UIDeviceOrientationPortrait) {
            t = CGAffineTransformMakeRotation(0);
        } 
        else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
            t = CGAffineTransformMakeRotation(M_PI);
        } 
        else if (orientation == UIDeviceOrientationLandscapeRight) {
            t = CGAffineTransformMakeRotation(-M_PI / 2);
        } 
        else {
            t = CGAffineTransformMakeRotation(M_PI / 2);
        }
        
        CIImage *orientedImage = [image imageByApplyingTransform:t];
        
        NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
        
        NSArray *features = [detector featuresInImage:orientedImage];
        
        CGFloat scale = [UIScreen mainScreen].scale;
        
        //NSLog(@"Faces: %i", [features count]);
        
        if ([features count] > 0) {
            
            CIFaceFeature *f = [features objectAtIndex:0];
            CGPoint stache1Center = CGPointMake(abs(f.mouthPosition.x / scale),
                                                abs(f.mouthPosition.y / scale));
            
            
            float eyeDistance = f.rightEyePosition.x - f.leftEyePosition.x;
            
            //NSLog(@"******");
            //NSLog(@"EYE DISTANCE: %f", eyeDistance);
            
            float stacheScaleFactor = eyeDistance / 110;
            
            float eyeVerticalDistance = f.rightEyePosition.y - f.leftEyePosition.y;
            
            float angleRadians = 0;
            
            if (eyeVerticalDistance != 0) {
                angleRadians = asinf(eyeDistance / eyeVerticalDistance);
            }
            
            //NSLog(@"EYE VERTICAL DISTANCE: %f", eyeVerticalDistance);
            //NSLog(@"Face Angle Degrees: %f", 
            //      [Trig angleDegreesBetweenFirstPoint:f.rightEyePosition andSecondPoint:f.leftEyePosition]);
            //NSLog(@"******");
            
            float faceAngleRadians = [Trig angleRadiansBetweenFirstPoint:f.rightEyePosition andSecondPoint:f.leftEyePosition];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.stacheImage.transform = CGAffineTransformIdentity;
                CGRect oldFrame = self.stacheImage.frame;
                oldFrame.size = CGSizeMake(stacheScaleFactor * 87, stacheScaleFactor * 50);
                self.stacheImage.frame = oldFrame;
                self.stacheImage.center = stache1Center;
                self.stacheImage.transform = CGAffineTransformMakeRotation(-faceAngleRadians);
            });
        
        }
        
        [localPool drain];
        
        /*
        for (CIFaceFeature *f in features) {
            
            NSLog(@"Mouth %i: %d, %d",
                  [features indexOfObject:f],
                  abs(f.mouthPosition.x / scale),
                  abs(f.mouthPosition.y / scale));
            
        }
         */
    });
}


- (void)dealloc {
    [_stacheImage release];
    [super dealloc];
}
@end
