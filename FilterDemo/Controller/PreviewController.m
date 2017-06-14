//
//  PreviewController.m
//  FilterDemo
//
//  Created by wpsd on 2017/6/12.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "PreviewController.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

#define SCREEN_WIDTH UIScreen.mainScreen.bounds.size.width
#define SCREEN_HEIGHT UIScreen.mainScreen.bounds.size.height

@interface PreviewController ()<GPUImageMovieDelegate>

@property (strong, nonatomic) GPUImageMovie *movieFile;
@property (strong, nonatomic) GPUImageView *videoView;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) NSURL *movieURL;
@property (assign, nonatomic) NSInteger currentVideoIndex;

@property (assign, nonatomic) BOOL isStart;

@end

@implementation PreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.videoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view addSubview:self.videoView];
    
    self.currentVideoIndex = 1;
    [self setupVideo];
    [self setupUI];
    
}

- (void)setupVideo {
    
    self.movieURL = [NSURL fileURLWithPath:pathToMovie(self.currentVideoIndex)];
    
    self.playerItem = [AVPlayerItem playerItemWithURL:self.movieURL];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.movieFile = [[GPUImageMovie alloc] initWithPlayerItem:self.playerItem];
    self.movieFile.delegate = self;
    
    self.movieFile.runBenchmark = YES;
    self.movieFile.playAtActualSpeed = YES;
    [self.movieFile addTarget:self.videoView];
    [self.movieFile startProcessing];
    
    [self.movieFile.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    self.player.rate = 1.0;
    
}

- (void)setupUI {
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [backBtn sizeToFit];
    backBtn.frame = CGRectMake(50, 30, backBtn.frame.size.width, backBtn.frame.size.height);
    [backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    UIButton *replayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [replayBtn setTitle:@"重新播放" forState:UIControlStateNormal];
    [replayBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [replayBtn sizeToFit];
    replayBtn.frame = CGRectMake(150, 30, replayBtn.frame.size.width, replayBtn.frame.size.height);
    [replayBtn addTarget:self action:@selector(replayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:replayBtn];
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveBtn setTitle:@"保存到相册" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [saveBtn sizeToFit];
    saveBtn.frame = CGRectMake(250, 30, saveBtn.frame.size.width, saveBtn.frame.size.height);
    [saveBtn addTarget:self action:@selector(saveToAlbumBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveBtn];
    
}

- (void)saveToAlbumBtnClick:(UIButton *)sender {
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie((long)1))) {
        [library writeVideoAtPathToSavedPhotosAlbum:self.movieURL completionBlock:^(NSURL *assetURL, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存到相册成功" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            });
        }];
        
    } else {
        NSLog(@"error msg)");
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        if ([[change objectForKey:@"new"] intValue] == AVPlayerStatusReadyToPlay) {
            CMTime duration = self.movieFile.playerItem.duration;
            if (duration.timescale == 0 || self.isStart == YES) { return; }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration.value / duration.timescale * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.isStart = YES;
                [self.movieFile endProcessing];
            });
        }
    }
    
}

#pragma mark - Actions

- (void)replayBtnClick:(UIButton *)sender {
    
    self.currentVideoIndex = 1;
    [self.movieFile endProcessing];
    [self setupVideo];
    
}

- (void)backBtnClick:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - GPUImageMovieDelegate

- (void)didCompletePlayingMovie {
    
    self.isStart = NO;
    if (self.currentVideoIndex <= self.videoCount) {
        self.currentVideoIndex += 1;
        [self.movieFile removeAllTargets];
        self.movieFile = nil;
        self.player = nil;
        self.playerItem = nil;
        [self setupVideo];
    }else {
        self.currentVideoIndex = 1;
    }
    
}

@end
