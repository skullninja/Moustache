//
//  DemoVideoCaptureViewController.m
//  FaceTracker
//
//  Created by Robin Summerhill on 9/22/11.
//  Copyright 2011 Aptogo Limited. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "UIImage+OpenCV.h"
#import "DemoVideoCaptureViewController.h"
#import "DetectedFaceFeatures.h"

@implementation DemoVideoCaptureViewController
@synthesize imagePreview = _imagePreview;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.captureGrayscale = YES;
        self.qualityPreset = AVCaptureSessionPresetMedium;
        _faceProcessor = [[FaceProcessor alloc] init];
        _faceProcessor.delegate = self;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewDidUnload {
    [self setImagePreview:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation  {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// MARK: IBActions

// Toggles display of FPS
- (IBAction)toggleFps:(id)sender {
    self.showDebugInfo = !self.showDebugInfo;
}

// Turn torch on and off
- (IBAction)toggleTorch:(id)sender {
    self.torchOn = !self.torchOn;
}
  
// Switch between front and back camera
- (IBAction)toggleCamera:(id)sender {
    if (self.camera == 1) {
        self.camera = 0;
    }
    else {
        self.camera = 1;
    }
}

// MARK: VideoCaptureViewController overrides


- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videOrientation {
    [_faceProcessor processFrame:mat videoRect:rect videoOrientation:videOrientation];
}

// MARK: FaceProcessorDelegate

- (void)previewImageUpdated:(UIImage *)previewImage {
    self.imagePreview.image = previewImage;
}

- (void)facesUpdated:(NSArray *)faces videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)orientation {

    NSArray *sublayers = [NSArray arrayWithArray:[self.view.layer sublayers]];
    int sublayersCount = [sublayers count];
    int currentSublayer = 0;
    
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for (CALayer *layer in sublayers) {
        NSString *layerName = [layer name];
		if ([layerName isEqualToString:@"FaceLayer"])
			[layer setHidden:YES];
	}	
    
    // Create transform to convert from vide frame coordinate space to view coordinate space
    CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:orientation];
    
    for (int i = 0; i < [faces count]; i++) {
        
        DetectedFaceFeatures *face = [faces objectAtIndex:i];
        
        CGRect faceRect;
        faceRect.size.width = face.mouthRight.x - face.mouthLeft.x;
        faceRect.size.height = face.mouthBottomLip.y - face.mouthUpperLip.y;
        faceRect.origin.x = face.mouthLeft.x;
        faceRect.origin.y = face.mouthUpperLip.y - ((face.mouth.y - face.leftEye.y) * 0.20);
        
        faceRect = CGRectApplyAffineTransform(faceRect, t);
        
        /*
        //HACK:
        faceRect = CGRectMake(faceRect.origin.x + (faceRect.size.width * 0.25),
                              faceRect.origin.y + (faceRect.size.height * 0.60),
                              faceRect.size.width * .5,
                              faceRect.size.height * .25);
        */
         
        CALayer *featureLayer = nil;
        
        while (!featureLayer && (currentSublayer < sublayersCount)) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ([[currentLayer name] isEqualToString:@"FaceLayer"]) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
        
        if (!featureLayer) {
            // Create a new feature marker layer
			featureLayer = [[CALayer alloc] init];
            featureLayer.contents = (id)[UIImage imageNamed:@"stache"].CGImage;
            
            featureLayer.name = @"FaceLayer";
            featureLayer.borderColor = [[UIColor clearColor] CGColor];
            //featureLayer.borderWidth = 10.0f;
			[self.view.layer addSublayer:featureLayer];
			[featureLayer release];
		}
        
        featureLayer.frame = faceRect;
    }
    
    [CATransaction commit];
    
}

- (void)dealloc {
    [_faceProcessor release];
    [_imagePreview release];
    [super dealloc];
}
@end
