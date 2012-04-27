//
//  VideoViewController.m
//  Moustache
//
//  Created by Dave Peck on 4/26/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import "VideoViewController.h"

@interface VideoViewController ()
- (BOOL)createCaptureSessionForCamera:(NSInteger)camera qualityPreset:(NSString *)qualityPreset;
- (void)tearDownCaptureSession;

@end

@implementation VideoViewController

@synthesize camera = _camera;
@synthesize captureSession = _captureSession;
@synthesize captureDevice = _captureDevice;
@synthesize videoOutput = _videoOutput;
@synthesize context = _context;
@synthesize videoPreviewLayer = _videoPreviewLayer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _camera = 1;
    }
    return self;
}

- (void)dealloc {
    [self tearDownCaptureSession];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    _coreImageContext = [[CIContext contextWithEAGLContext:self.context] retain];
    
    [self createCaptureSessionForCamera:_camera qualityPreset:AVCaptureSessionPresetPhoto];
    [_captureSession startRunning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self tearDownCaptureSession];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

// Tear down the video capture session
- (void)tearDownCaptureSession {
    
    [_captureSession stopRunning];
    
    [_videoPreviewLayer removeFromSuperlayer];
    [_videoPreviewLayer release];
    [_videoOutput release];
    [_captureDevice release];
    [_captureSession release];
    
    _videoOutput = nil;
    _captureDevice = nil;
    _captureSession = nil;
    _videoPreviewLayer = nil;
}

// Switch camera
// camera: 0 for back camera, 1 for front camera
- (void)setCamera:(int)camera {
    if (camera != _camera) {
        _camera = camera;
        
        if (_captureSession) {
            NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
            
            [_captureSession beginConfiguration];
            
            [_captureSession removeInput:[[_captureSession inputs] lastObject]];
            
            [_captureDevice release];
            
            if (_camera >= 0 && _camera < [devices count]) {
                _captureDevice = [devices objectAtIndex:camera];
            } 
            else {
                _captureDevice = [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] retain];
            }
            
            // Create device input
            NSError *error = nil;
            AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
            [_captureSession addInput:input];
            
            [_captureSession commitConfiguration];
        }
    }
}

- (BOOL)createCaptureSessionForCamera:(NSInteger)camera qualityPreset:(NSString *)qualityPreset {
	
    // Set up AV capture
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    if ([devices count] == 0) {
        NSLog(@"No video capture devices found");
        return NO;
    }
    
    if (camera == -1) {
        _camera = -1;
        _captureDevice = [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] retain];
    }
    else if (camera >= 0 && camera < [devices count]) {
        _camera = camera;
        _captureDevice = [[devices objectAtIndex:camera] retain];
    }
    else {
        _camera = -1;
        _captureDevice = [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] retain];
        NSLog(@"Camera number out of range. Using default camera");
    }
    
    // Create the capture session
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = (qualityPreset)? qualityPreset : AVCaptureSessionPresetMedium;
    
    // Create device input
    NSError *error = nil;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
    
    // Create and configure device output
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL); 
    [_videoOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue); 
    
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    _videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // Connect up inputs and outputs
    if ([_captureSession canAddInput:input]) {
        [_captureSession addInput:input];
    }
    
    if ([_captureSession canAddOutput:_videoOutput]) {
        [_captureSession addOutput:_videoOutput];
    }
    
    [input release];
    
    // Create the preview layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setFrame:self.view.bounds];
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:_videoPreviewLayer atIndex:0];
     
    return YES;
}

// Override to manipulate frame.
- (void)processCameraImage:(CIImage *)image {

}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection {
    
    NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *image = [[[CIImage alloc] initWithCVPixelBuffer:pixelBuffer] autorelease];
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    CGAffineTransform t;
    
    if (orientation == UIDeviceOrientationPortrait) {
        t = CGAffineTransformMakeRotation(-M_PI / 2);
    } 
    else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        t = CGAffineTransformMakeRotation(M_PI / 2);
    } 
    else if (orientation == UIDeviceOrientationLandscapeRight) {
        t = CGAffineTransformMakeRotation(M_PI);
    } 
    else {
        t = CGAffineTransformMakeRotation(0);
    }
    
    //image = [image imageByApplyingTransform:t];
    image = [image imageByApplyingTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    
    [self processCameraImage:image];
    
    //[_coreImageContext drawImage:image atPoint:CGPointZero fromRect:[image extent]];
    //[self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    [localpool drain];
}


@end
