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

@implementation DetectedFace 

@synthesize mouth = _mouth;
@synthesize mouthUpperLip = _mouthUpperLip;
@synthesize mouthBottomLip = _mouthBottomLip;
@synthesize mouthLeft = _mouthLeft;
@synthesize mouthRight = _mouthRight;
@synthesize leftEye = _leftEye;
@synthesize rightEye = _rightEye;

@end

// Name of face cascade resource file without xml extension
//NSString * const kFaceCascadeFilename = @"lbpcascade_frontalface";
NSString * const kFaceCascadeFilename = @"haarcascade_frontalface_alt2";
int const kNumberOfFaceFeaturesTracked = 7;

// Options for cv::CascadeClassifier::detectMultiScale
//const int kHaarOptions =  CV_HAAR_FIND_BIGGEST_OBJECT | CV_HAAR_DO_ROUGH_SEARCH;
const int kHaarOptions =  CV_HAAR_DO_ROUGH_SEARCH;// | CV_HAAR_DO_CANNY_PRUNING;

@interface DemoVideoCaptureViewController ()
- (void)displayFaces:(const std::vector<cv::Rect> &)faces 
       forVideoRect:(CGRect)rect 
    videoOrientation:(AVCaptureVideoOrientation)videoOrientation;
- (void)displayFacesAlt:(NSArray *)faces 
        forVideoRect:(CGRect)rect 
    videoOrientation:(AVCaptureVideoOrientation)videoOrientation;
@end

@implementation DemoVideoCaptureViewController
@synthesize imagePreview = _imagePreview;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.captureGrayscale = YES;
        self.qualityPreset = AVCaptureSessionPresetMedium;
        _faces = [[NSMutableArray alloc] initWithCapacity:4];
        _framesSinceLastFeatureCheck = 0;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the face Haar cascade from resources
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
    
    if (!_faceCascade.load([faceCascadePath UTF8String])) {
        NSLog(@"Could not load face cascade: %@", faceCascadePath);
    }
}

- (void)viewDidUnload
{
    [self setImagePreview:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// MARK: IBActions

// Toggles display of FPS
- (IBAction)toggleFps:(id)sender
{
    self.showDebugInfo = !self.showDebugInfo;
}

// Turn torch on and off
- (IBAction)toggleTorch:(id)sender
{
    self.torchOn = !self.torchOn;
}
  
// Switch between front and back camera
- (IBAction)toggleCamera:(id)sender
    {
    if (self.camera == 1) {
        self.camera = 0;
    }
    else
    {
        self.camera = 1;
    }
}

// MARK: VideoCaptureViewController overrides

- (BOOL)addNewPoints {
    return _framesSinceLastFeatureCheck > 60 || _points[0].size() < MAX(1, (kNumberOfFaceFeaturesTracked * [_faces count]));
}

- (void)detectFeaturedPoints:(cv::Mat &)mat {
    
    //NSLog(@"Trying to add points");
    
    /*
    std::vector<cv::Rect> faces;
    
    _faceCascade.detectMultiScale(mat, faces, 1.1, 2, kHaarOptions, cv::Size(45, 45));
    
    NSLog(@"*** FACES FOUND ***");
    
    for (int j = 0; j < faces.size(); j++) {
        NSLog(@"x:%i, y:%i", faces[j].x, faces[j].y);
    }
    
    NSLog(@"*** *** ***");
    
    */
    
    _framesSinceLastFeatureCheck = 0;
     
    UIImage *tempImage = [UIImage imageWithCVMat:mat];
    CIImage *orientedImage = [CIImage imageWithCGImage:tempImage.CGImage];
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
    
    NSArray *faces = [detector featuresInImage:orientedImage];
    
    if ([faces count] == 0) {
        NSLog(@"Number of Points: %lu", _points[0].size());
        if (_points[0].size() == (kNumberOfFaceFeaturesTracked * [_faces count])) {
            return; // If no faces are found, then do not clear any existing points (assuming they are valid).
        }
    }
    
    //Reject all existing points
    _points[0].clear();
    _points[1].clear();
    _initial.clear();
    
    _features.clear();
    [_faces removeAllObjects];
    
    float upperLipFactor = 0.92;
    float bottomLipFactor = 1.08;
     
    for (CIFaceFeature *face in faces) {
        
        if (!face.hasMouthPosition || !face.hasLeftEyePosition
            || !face.hasRightEyePosition) continue;

        // Mouth Center
        _features.insert(_features.end(), cv::Point2f(face.mouthPosition.x, tempImage.size.height - face.mouthPosition.y));
        
        // Upper Lip
        _features.insert(_features.end(), cv::Point2f(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * upperLipFactor));
        
        // Bottom Lip
        _features.insert(_features.end(), cv::Point2f(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * bottomLipFactor));
        
        // Mouth Left / Right
        _features.insert(_features.end(), cv::Point2f(face.leftEyePosition.x, tempImage.size.height - face.mouthPosition.y));
        _features.insert(_features.end(), cv::Point2f(face.rightEyePosition.x, tempImage.size.height - face.mouthPosition.y));
        
        // Left / Right Eyes
        _features.insert(_features.end(), cv::Point2f(face.leftEyePosition.x, tempImage.size.height - face.leftEyePosition.y));
        _features.insert(_features.end(), cv::Point2f(face.rightEyePosition.x, tempImage.size.height - face.rightEyePosition.y));
        
        
        
        

        DetectedFace *df = [[[DetectedFace alloc] init] autorelease];
        df.mouth = CGPointMake(face.mouthPosition.x, tempImage.size.height - face.mouthPosition.y);
        df.mouthUpperLip = CGPointMake(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * upperLipFactor);
        df.mouthBottomLip = CGPointMake(face.mouthPosition.x, (tempImage.size.height - face.mouthPosition.y) * bottomLipFactor);
        df.mouthLeft = CGPointMake(face.leftEyePosition.x, tempImage.size.height - face.mouthPosition.y);
        df.mouthRight = CGPointMake(face.rightEyePosition.x, tempImage.size.height - face.mouthPosition.y);
        df.leftEye = CGPointMake(face.leftEyePosition.x, tempImage.size.height - face.leftEyePosition.y);
        df.rightEye = CGPointMake(face.rightEyePosition.x, tempImage.size.height - face.rightEyePosition.y);
        
        [_faces addObject:df];
    }
    
    // add the detected features to
    // the currently tracked features
    _points[0].insert(_points[0].end(),
                      _features.begin(),_features.end());
    _initial.insert(_initial.end(),
                    _features.begin(),_features.end());
    
     
     /*
    
    std::vector<cv::Point2f> tempFeatures;
    _features.clear();
    
    cv::goodFeaturesToTrack(mat, // the image
                            tempFeatures,   // the output detected features
                            10,  // the maximum number of features
                            0.01,     // quality level
                            10);   // min distance between two features
    

    
    for (int i = 0; i < tempFeatures.size(); i++) {
        
        cv::Point2f pt = tempFeatures[i];
        
        for (int j = 0; j < faces.size(); j++) {
         
            cv::Rect face = faces[j];
            
            if (pt.x >= face.x && pt.x <= (face.x + face.width)
                && pt.y >= face.y && pt.y <= (face.y + face.height)) {
                 
                    _features.insert(_features.end(), pt);
                    
                }
        }
    }
     
     */
}

- (BOOL)acceptTrackedPoint:(int)i {
    return _status[i];// &&
    // if point has moved
    //(abs(_points[0][i].x-_points[1][i].x)+
     //(abs(_points[0][i].y-_points[1][i].y))>2);
}

// handle the currently tracked points
- (void)handleTrackedPoints:(cv:: Mat &)frame output:(cv:: Mat &)output {
    
    
    cv::Mat clone = frame.clone();
    
    // for all tracked points
    for(int i= 0; i < _points[1].size(); i++ ) {
        // draw line and circle
        cv::line(clone,
                 _initial[i],  // initial position
                 _points[1][i],// new position
                 cv::Scalar(255,255,255));
        cv::circle(clone, _points[1][i], 3,
                   cv::Scalar(255,255,255),-1);
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.imagePreview.image = [UIImage imageWithCVMat:clone];
        
    });
    
}

- (void)processFrame:(cv::Mat &)mat videoRect:(CGRect)rect videoOrientation:(AVCaptureVideoOrientation)videOrientation
{
    // Shrink video frame to 320X240
    cv::resize(mat, mat, cv::Size(), 0.25f, 0.25f, CV_INTER_LINEAR);
    rect.size.width /= 4.0f;
    rect.size.height /= 4.0f;
    
    //Sharpen
    //cv::Mat clone = mat.clone();
    //cv::GaussianBlur(clone, mat, cv::Size(), 3);
    //cv::addWeighted(clone, 1.5, mat, -0.5, 0, mat);
    
    // Rotate video frame by 90deg to portrait by combining a transpose and a flip
    // Note that AVCaptureVideoDataOutput connection does NOT support hardware-accelerated
    // rotation and mirroring via videoOrientation and setVideoMirrored properties so we
    // need to do the rotation in software here.
    cv::transpose(mat, mat);
    CGFloat temp = rect.size.width;
    rect.size.width = rect.size.height;
    rect.size.height = temp;
    
    if (videOrientation == AVCaptureVideoOrientationLandscapeRight)
    {
        // flip around y axis for back camera
        cv::flip(mat, mat, 1);
    }
    else {
        // Front camera output needs to be mirrored to match preview layer so no flip is required here
    }
       
    videOrientation = AVCaptureVideoOrientationPortrait;
    
    if ([self addNewPoints]) {
        
        // Check for faces
        [self detectFeaturedPoints:mat];
        
    } else {
        _framesSinceLastFeatureCheck++;
    }
    
    if (_prevMat.empty()) {
        mat.copyTo(_prevMat);
    }
    
    if (_points[0].size() > 0) {
    
        cv::calcOpticalFlowPyrLK(
                                 _prevMat, mat, // 2 consecutive images
                                 _points[0], // input point positions in first image
                                 _points[1], // output point positions in the 2nd image
                                 _status,    // tracking success
                                 _err);
        
        
        // 2. loop over the tracked points to reject some
        int k=0;
        int accepted = 0;
        int rejected = 0;
        for( int i= 0; i < _points[1].size(); i++ ) {
            // do we keep this point?
            if ([self acceptTrackedPoint:i]) {
                accepted++;
                // keep this point in vector
                _initial[k]= _initial[i];
                _points[1][k++] = _points[1][i];
                
                DetectedFace *df = [_faces objectAtIndex:(int)(i / kNumberOfFaceFeaturesTracked)];
                
                int currentFeature = i % kNumberOfFaceFeaturesTracked;
                
                switch (currentFeature) {
                    case 0:
                        df.mouth = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 1:
                        df.mouthUpperLip = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 2:
                        df.mouthBottomLip = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 3:
                        df.mouthLeft = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 4:
                        df.mouthRight = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 5:
                        df.leftEye = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                    case 6:
                        df.rightEye = CGPointMake(_points[1][i].x, _points[1][i].y);
                        break;
                }
                
            } else {
                rejected++;
            }
        }
        
        //NSLog(@"Accepted: %i; Rejected: %i", accepted, rejected);
        
        // eliminate unsuccesful points
        _points[1].resize(k);
        _initial.resize(k);
    }

    // 4. current points and image become previous ones
    std::swap(_points[1], _points[0]);
    cv::swap(_prevMat, mat);

    // 3. handle the accepted tracked points
    [self handleTrackedPoints:mat output:mat];
    
    // Dispatch updating of face markers to main queue
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self displayFacesAlt:_faces
              forVideoRect:rect
          videoOrientation:videOrientation];    
    });
    
    /*
    // Detect faces
    std::vector<cv::Rect> faces;
    std::vector<cv::KeyPoint> keypoints;
    
    _faceCascade.detectMultiScale(mat, faces, 1.1, 2, kHaarOptions, cv::Size(45, 45));
    
    cv::GoodFeaturesToTrackDetector detector(10, 0.01, 10);
    
    //cv::FastFeatureDetector detector(10);
    
    detector.detect(mat, keypoints);
    
    

    
    // Dispatch updating of face markers to main queue
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self displayFaces:faces
             forVideoRect:rect
          videoOrientation:videOrientation];    
    });
    
    */
    
}

- (void)displayFacesAlt:(NSArray *)faces 
           forVideoRect:(CGRect)rect 
       videoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    
    
    
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
    CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:videoOrientation];
    
    for (int i = 0; i < [faces count]; i++) {
        
        DetectedFace *face = [faces objectAtIndex:i];
        
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

// Update face markers given vector of face rectangles
- (void)displayFaces:(const std::vector<cv::Rect> &)faces 
       forVideoRect:(CGRect)rect 
    videoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
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
    CGAffineTransform t = [self affineTransformForVideoFrame:rect orientation:videoOrientation];

    for (int i = 0; i < faces.size(); i++) {
  
        CGRect faceRect;
        faceRect.origin.x = faces[i].x;
        faceRect.origin.y = faces[i].y;
        faceRect.size.width = faces[i].width;
        faceRect.size.height = faces[i].height;
    
        faceRect = CGRectApplyAffineTransform(faceRect, t);
        
        //HACK:
        faceRect = CGRectMake(faceRect.origin.x + (faceRect.size.width * 0.25),
                              faceRect.origin.y + (faceRect.size.height * 0.60),
                              faceRect.size.width * .5,
                              faceRect.size.height * .25);
        
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
    [_imagePreview release];
    [super dealloc];
}
@end
