//
//  FirstViewController.m
//  Moustache
//
//  Created by Dave Peck on 4/26/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import "FirstViewController.h"
#import <CoreImage/CoreImage.h>

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _faceQueue = dispatch_queue_create("faceQueue", NULL); 
    
    _tryCount = 0;
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self setCamera:self.camera == 1 ? 0 : 1];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

- (void)processCameraImage:(CIImage *)image {
    
    dispatch_async(_faceQueue, ^{
        
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
        
        NSLog(@"Faces: %i", [features count]);
    });
}


- (void)dealloc {
    [super dealloc];
}
@end
