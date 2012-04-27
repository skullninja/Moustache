//
//  VideoViewController.h
//  Moustache
//
//  Created by Dave Peck on 4/26/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoViewController : GLKViewController<AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_captureDevice;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
    
    CIContext *_coreImageContext;
    GLuint _renderBuffer;
    
    int _camera;
}

// OpenGL Context
@property (strong, nonatomic) EAGLContext *context;

// AVFoundation components
@property (nonatomic, readonly) AVCaptureSession *captureSession;
@property (nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (nonatomic, readonly) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

// -1: default, 0: back camera, 1: front camera
@property (nonatomic, assign) int camera;

- (void)processCameraImage:(CIImage *)image;

@end
