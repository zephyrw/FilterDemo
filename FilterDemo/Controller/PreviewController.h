//
//  PreviewController.h
//  FilterDemo
//
//  Created by wpsd on 2017/6/12.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PreviewController : UIViewController

@property (assign, nonatomic) NSInteger videoCount;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end
