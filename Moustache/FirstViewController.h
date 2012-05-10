//
//  FirstViewController.h
//  Moustache
//
//  Created by Dave Peck on 4/26/12.
//  Copyright (c) 2012 Skull Ninja Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoViewController.h"

@interface FirstViewController : VideoViewController {
    int _tryCount;
    dispatch_queue_t _faceQueue;
    BOOL _processFrame;
}
@property (retain, nonatomic) IBOutlet UIImageView *stacheImage;

@end
