//
//  DemoVideoCaptureViewController.h
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

#import "VideoCaptureViewController.h"

@interface DetectedFace : NSObject {
    CGPoint _mouth;
    CGPoint _mouthUpperLip;
    CGPoint _mouthBottomLip;
    CGPoint _mouthLeft;
    CGPoint _mouthRight;
    CGPoint _leftEye;
    CGPoint _rightEye;
}

@property (readwrite, nonatomic, assign) CGPoint mouth;
@property (readwrite, nonatomic, assign) CGPoint mouthUpperLip;
@property (readwrite, nonatomic, assign) CGPoint mouthBottomLip;
@property (readwrite, nonatomic, assign) CGPoint mouthLeft;
@property (readwrite, nonatomic, assign) CGPoint mouthRight;
@property (readwrite, nonatomic, assign) CGPoint leftEye;
@property (readwrite, nonatomic, assign) CGPoint rightEye;

@end

@interface DemoVideoCaptureViewController : VideoCaptureViewController
{
    cv::CascadeClassifier _faceCascade;
    cv::Mat _prevMat;
    std::vector<cv::Point2f> _points[2];
    std::vector<cv::Point2f> _features;
    std::vector<cv::Point2f> _initial;
    std::vector<uchar> _status;
    std::vector<float> _err;
    
    int _framesSinceLastFeatureCheck;
    
    NSMutableArray *_faces;
}
@property (retain, nonatomic) IBOutlet UIImageView *imagePreview;

- (IBAction)toggleFps:(id)sender;
- (IBAction)toggleTorch:(id)sender;
- (IBAction)toggleCamera:(id)sender;

@end
