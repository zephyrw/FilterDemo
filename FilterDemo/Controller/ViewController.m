//
//  ViewController.m
//  FilterDemo
//
//  Created by wpsd on 2017/5/26.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ViewController.h"
#import "GPUImageBeautifyFilter.h"
#import "FilterCell.h"
#import "FilterModel.h"

#import <iflyMSC/IFlyFaceSDK.h>
#import <CoreMotion/CMMotionManager.h>
#import "IFlyFaceImage.h"
#import "CanvasView.h"
#import "IFlyFaceResultKeys.h"
#import "CalculatorTools.h"
// filters
#import "FWNashvilleFilter.h"
#import "FWLordKelvinFilter.h"
#import "PreviewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, RecordType){
    RecordTypeStoping,
    RecordTypeRecording,
    RecordTypeSaving
};

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, GPUImageVideoCameraDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (strong, nonatomic) GPUImageFilterGroup *filterGroup;
@property (strong, nonatomic) GPUImageFilterGroup *originFilterGroup;
@property (strong, nonatomic) GPUImageBeautifyFilter *beautifulFilter;
@property (nonatomic, strong) UIButton *beautifyButton;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray<FilterModel *> *filters;
@property (nonatomic , strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic , strong) GPUImageUIElement *faceView;
@property (nonatomic , strong) GPUImageAddBlendFilter *blendFilter;
/*
 人脸识别
 */
@property (nonatomic, retain) IFlyFaceDetector *faceDetector;
@property (nonatomic , strong) CanvasView *viewCanvas;
/*
 Device orientation
 */
@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;
@property (strong, nonatomic) NSURL *movieURL;
@property (assign, nonatomic) BOOL isRecording;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) UIButton *startRecordBtn;
@property (assign, nonatomic) NSInteger videoCount;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) CADisplayLink *link;

@end

@implementation ViewController

static NSString *cellID = @"CellID";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupFaceDetector];
    [self setupFilters];
    [self setupMovieWriter];
    [self setupResponseChain];
    [self setupAudioPlayer];
    [self setupUI];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.videoCamera startCameraCapture];
    
}

- (void)setupFaceDetector {
    
    // 人脸识别
    self.viewCanvas = [[CanvasView alloc] initWithFrame:self.view.bounds];
    self.viewCanvas.backgroundColor = [UIColor clearColor];
    self.viewCanvas.headMap = [UIImage imageNamed:@"Crown"];
    self.faceDetector = [IFlyFaceDetector sharedInstance];
    if(self.faceDetector){
        [self.faceDetector setParameter:@"1" forKey:@"detect"];
        [self.faceDetector setParameter:@"1" forKey:@"align"];
    }
    
}

- (void)setupFilters {
    
    // 滤镜初始化
    self.faceView = [[GPUImageUIElement alloc] initWithView:self.viewCanvas];
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.delegate = self;
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.filterView];
    
    self.beautifulFilter = [GPUImageBeautifyFilter new];
    self.filterGroup = [GPUImageFilterGroup new];
    [self addGPUImageFilter:self.beautifulFilter];
    self.originFilterGroup = [GPUImageFilterGroup new];
    self.originFilterGroup.initialFilters = @[self.beautifulFilter];
    self.originFilterGroup.terminalFilter = self.beautifulFilter;
    self.blendFilter = [[GPUImageAddBlendFilter alloc] init];
    
}

- (void)setupMovieWriter {
    
    if (self.movieWriter) {
        self.movieWriter = nil;
    }
    
    // 录像文件
    unlink([pathToMovie(self.videoCount) UTF8String]);
    self.movieURL = [NSURL fileURLWithPath:pathToMovie(self.videoCount)];
    
    // 配置录制信息
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(480, 640)];
    _movieWriter.encodingLiveVideo = YES;
//    [self.videoCamera startCameraCapture];
    
}

- (void)setupResponseChain {
    
    if (self.videoCamera.targets.count) {
        [self.videoCamera removeAllTargets];
    }
    if (self.filterGroup.targets.count) {
        [self.filterGroup removeAllTargets];
    }
    if (self.faceView.targets.count) {
        [self.faceView removeAllTargets];
    }
    if (self.blendFilter.targets.count) {
        [self.blendFilter removeAllTargets];
    }
    
    [self.videoCamera addTarget:self.filterGroup];
    [self.filterGroup addTarget:self.blendFilter];
    [self.faceView addTarget:self.blendFilter];
    [self.filterGroup addTarget:self.filterView];
    [self.blendFilter addTarget:_movieWriter];
    
}


- (void)addGPUImageFilter:(GPUImageOutput<GPUImageInput> *)filter {
    
    [self.filterGroup addFilter:filter];
    
    if (self.filterGroup.filterCount == 1) {
        self.filterGroup.initialFilters = @[filter];
        self.filterGroup.terminalFilter = filter;
    }else {
        [self.filterGroup.terminalFilter addTarget:filter];
        self.filterGroup.initialFilters = @[self.filterGroup.initialFilters.firstObject];
        self.filterGroup.terminalFilter = filter;
    }
    
}

- (void)setupAudioPlayer {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ywcm" ofType:@"mp3"];
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:&error];
    if (error) {
        NSLog(@"音频播放器初始化错误");
        return;
    }
    self.audioPlayer.delegate = self;
    [self.audioPlayer addObserver:self forKeyPath:@"currentTime" options:NSKeyValueObservingOptionNew context:nil];
    [self.audioPlayer prepareToPlay];
    
}

- (void)setupUI {
    
    self.filters = [FilterModel filters];
    [self.view addSubview:self.viewCanvas];
    
    UIButton *coverBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    coverBtn.frame = self.filterView.frame;
    [coverBtn addTarget:self action:@selector(coverBtnTouchDown:) forControlEvents:UIControlEventTouchDown];
    [coverBtn addTarget:self action:@selector(coverBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:coverBtn];
    
    UIButton *startRecordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.startRecordBtn = startRecordBtn;
    [startRecordBtn setTitle:@"开始录制" forState:UIControlStateNormal];
    [startRecordBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [startRecordBtn sizeToFit];
    startRecordBtn.frame = CGRectMake(50, 30, startRecordBtn.frame.size.width, startRecordBtn.frame.size.height);
    [startRecordBtn addTarget:self action:@selector(startRecordBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecordBtn];
    
    UIButton *rotateCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rotateCameraBtn setTitle:@"翻转镜头" forState:UIControlStateNormal];
    [rotateCameraBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [rotateCameraBtn sizeToFit];
    rotateCameraBtn.frame = CGRectMake(150, 30, rotateCameraBtn.frame.size.width, rotateCameraBtn.frame.size.height);
    [rotateCameraBtn addTarget:self action:@selector(rotateCameraBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:rotateCameraBtn];
    
    UIButton *finishRecordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [finishRecordBtn setTitle:@"完成录制" forState:UIControlStateNormal];
    [finishRecordBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [finishRecordBtn sizeToFit];
    finishRecordBtn.frame = CGRectMake(250, 30, finishRecordBtn.frame.size.width, finishRecordBtn.frame.size.height);
    [finishRecordBtn addTarget:self action:@selector(finishRecordBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:finishRecordBtn];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 2)];
    progressView.progressTintColor = [UIColor orangeColor];
    progressView.trackTintColor = [UIColor grayColor];
    [self.view addSubview:progressView];
    self.progressView = progressView;
    
    [self.view addSubview:self.collectionView];
    
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(audioProcess)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.link = link;
    
}

- (void)audioProcess {
    
    self.progressView.progress = self.audioPlayer.currentTime / self.audioPlayer.duration;
    
}

#pragma mark - Actions

- (void)rotateCameraBtnClick:(UIButton *)sender {
    
    [self.videoCamera rotateCamera];
    
}

- (void)startRecordBtnClick:(UIButton *)sender {
    
    self.isRecording = !self.isRecording;
    if (self.isRecording) { // 开始录制
        ++self.videoCount;
        [sender setTitle:@"暂停录制" forState:UIControlStateNormal];
        NSLog(@"start record button click");
        [self setupMovieWriter];
        [self.videoCamera startCameraCapture];
        [self setupResponseChain];
        [self.movieWriter startRecording];
        [self.audioPlayer play];
        // 结束回调
        __weak typeof (self) weakSelf = self;
        [self.filterGroup setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            //        NSLog(@"update ui");
            __strong typeof (self) strongSelf = weakSelf;
            dispatch_async([GPUImageContext sharedContextQueue], ^{
                [strongSelf.faceView updateWithTimestamp:time];
            });
        }];
        
    }else { // 暂停录制
        [sender setTitle:@"继续录制" forState:UIControlStateNormal];
        NSLog(@"stop record button click");
        [self.audioPlayer pause];
        [self.blendFilter removeTarget:_movieWriter];
        [self.movieWriter finishRecording];
        self.filterGroup.frameProcessingCompletionBlock = nil;
//        [self.videoCamera stopCameraCapture];
        
    }
}

- (void)finishRecordBtnClick {
    
    [self.blendFilter removeTarget:_movieWriter];
    [self.audioPlayer stop];
    [self.audioPlayer prepareToPlay];
    [_movieWriter finishRecording];
    [self.startRecordBtn setTitle:@"开始录制" forState:UIControlStateNormal];
    [self.videoCamera stopCameraCapture];
    
    PreviewController *previewVC = [PreviewController new];
    previewVC.videoCount = self.videoCount;
    self.isRecording = NO;
    [self presentViewController:previewVC animated:YES completion:nil];
    
}

- (void)coverBtnTouchDown:(UIButton *)sender {
    
    [self.videoCamera removeAllTargets];
    [self.filterGroup removeAllTargets];
    [self.originFilterGroup removeAllTargets];
    [self.videoCamera addTarget:self.originFilterGroup];
    [self.originFilterGroup addTarget:self.filterView];
    
}

- (void)coverBtnTouchUpInside:(UIButton *)sender {
    
    [self setupResponseChain];
    
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filters.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FilterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    cell.filterModel = self.filters[indexPath.item];
    return cell;
    
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FilterCell *cell = (FilterCell *)[collectionView cellForItemAtIndexPath:indexPath];
    self.filterGroup = cell.filterModel.filterGroup;
    [self addGPUImageFilter:self.beautifulFilter];
    [self setupResponseChain];
    
}

#pragma mark - GPUImageVideoCameraDelegate

- (void) willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    IFlyFaceImage *faceImg = [self faceImageFromSampleBuffer:sampleBuffer];
    //识别结果，json数据
    NSString *strResult = [self.faceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
    
    [self praseTrackResult:strResult OrignImage:faceImg];
    //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用
    faceImg.data = nil;
    faceImg = nil;
    
}

#pragma mark - 人脸识别

/*
 人脸识别,储存人脸各点坐标
 */
- (void)praseTrackResult:(NSString*)result OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!result){
        return;
    }
    
    @try {
        NSError *error;
        NSData *resultData = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *faceDic = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData = nil;
        if(!faceDic){
            return;
        }
        
        NSString *faceRet=[faceDic objectForKey:KCIFlyFaceResultRet];
        NSArray *faceArray=[faceDic objectForKey:KCIFlyFaceResultFace];
        faceDic = nil;
        
        int ret = 0;
        if (faceRet) {
            ret = [faceRet intValue];
        }
        //没有检测到人脸或发生错误
        if (ret || !faceArray || [faceArray count] < 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideFace];
            } ) ;
            return;
        }
        
        //检测到人脸
        NSMutableArray *arrPersons = [NSMutableArray array];
        
        for (id face in faceArray) {
            
            if(face && [face isKindOfClass:[NSDictionary class]]){
                
                NSDictionary *positionDic = [face objectForKey:KCIFlyFaceResultPosition];
                NSString *rectString = [self praseDetect:positionDic OrignImage: faceImg];
                positionDic = nil;
                
                NSDictionary *landmarkDic = [face objectForKey:KCIFlyFaceResultLandmark];
                NSMutableArray *strPoints = [self praseAlign:landmarkDic OrignImage:faceImg];
                landmarkDic = nil;
                
                
                NSMutableDictionary *dicPerson = [NSMutableDictionary dictionary] ;
                if (rectString) {
                    [dicPerson setObject:rectString forKey:RECT_KEY];
                }
                if (strPoints) {
                    [dicPerson setObject:strPoints forKey:POINTS_KEY];
                }
                
                strPoints = nil;
                
                [dicPerson setObject:@"0" forKey:RECT_ORI];
                [arrPersons addObject:dicPerson];
                
                dicPerson = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
                } ) ;
            }
        }
        faceArray = nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@", exception.name);
    }
    @finally {
    }
    
}

/*
 检测面部特征点
 */

- (NSMutableArray*)praseAlign:(NSDictionary* )landmarkDic OrignImage:(IFlyFaceImage*)faceImg{
    if(!landmarkDic){
        return nil;
    }
    // 判断摄像头方向
    BOOL isFrontCamera = self.videoCamera.cameraPosition == AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.view.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.view.frame.size.height / faceImg.width;
    
    NSMutableArray *arrStrPoints = [NSMutableArray array] ;
    NSEnumerator *keys = [landmarkDic keyEnumerator];
    for (id key in keys) {
        id attr = [landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            
            id attr = [landmarkDic objectForKey:key];
            CGFloat x = [[attr objectForKey:KCIFlyFaceResultPointX] floatValue];
            CGFloat y = [[attr objectForKey:KCIFlyFaceResultPointY] floatValue];
            
            CGPoint p = CGPointMake(y,x);
            
            if(!isFrontCamera){
                p = pSwap(p);
                p = pRotate90(p, faceImg.height, faceImg.width);
            }
            
            p = pScale(p, widthScaleBy, heightScaleBy);
            
            [arrStrPoints addObject:NSStringFromCGPoint(p)];
            
        }
    }
    return arrStrPoints;
    
}

//检测到人脸
- (void) showFaceLandmarksAndFaceRectWithPersonsArray:(NSMutableArray *)arrPersons{
    if (self.viewCanvas.hidden) {
        self.viewCanvas.hidden = NO ;
    }
    self.viewCanvas.arrPersons = arrPersons ;
//    NSLog(@"update arr");
    [self.viewCanvas setNeedsDisplay];
}

//没有检测到人脸或发生错误
- (void) hideFace {
    if (!self.viewCanvas.hidden) {
        self.viewCanvas.hidden = YES ;
    }
}


/*
 检测脸部轮廓
 */
- (NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!positionDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera = self.videoCamera.cameraPosition == AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.view.frame.size.width / faceImg.height;
    CGFloat heightScaleBy = self.view.frame.size.height / faceImg.width;
    
    CGFloat bottom = [[positionDic objectForKey:KCIFlyFaceResultBottom] floatValue];
    CGFloat top = [[positionDic objectForKey:KCIFlyFaceResultTop] floatValue];
    CGFloat left = [[positionDic objectForKey:KCIFlyFaceResultLeft] floatValue];
    CGFloat right = [[positionDic objectForKey:KCIFlyFaceResultRight] floatValue];
    
    float cx = (left+right)/2;
    float cy = (top + bottom)/2;
    float w = right - left;
    float h = bottom - top;
    
    float ncx = cy ;
    float ncy = cx ;
    
    CGRect rectFace = CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace = rSwap(rectFace);
        rectFace = rRotate90(rectFace, faceImg.height, faceImg.width);
        
    }
    
    rectFace = rScale(rectFace, widthScaleBy, heightScaleBy);
    rectFace = CGRectMake(rectFace.origin.x, rectFace.origin.y, rectFace.size.width, rectFace.size.height);
    return NSStringFromCGRect(rectFace);
    
}


- (IFlyFaceImage *)faceImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    //获取灰度图像数据
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    uint8_t *lumaBuffer  = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
    size_t width  = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef context=CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace,0);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    IFlyFaceDirectionType faceOrientation=[self faceImageOrientation];
    
    IFlyFaceImage* faceImage=[[IFlyFaceImage alloc] init];
    if(!faceImage){
        return nil;
    }
    
    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
    
    faceImage.data= (__bridge_transfer NSData*)CGDataProviderCopyData(provider);
    faceImage.width=width;
    faceImage.height=height;
    faceImage.direction=faceOrientation;
    
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);
    
    return faceImage;
}



- (void)updateCM {
    // 这里使用CoreMotion来获取设备方向以兼容iOS7.0设备 检测当前设备的方向 Home键向上还是向下。。。。
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 if (!error) {
                                                     [self updateAccelertionData:accelerometerData.acceleration];
                                                 }
                                                 else{
                                                     NSLog(@"%@", error);
                                                 }
                                             }];
}


#pragma mark  - 判断当前设备的方向
- (void)updateAccelertionData:(CMAcceleration)acceleration{
    UIInterfaceOrientation orientationNew;
    
    if (acceleration.x >= 0.75) {
        orientationNew = UIInterfaceOrientationLandscapeLeft;
    }
    else if (acceleration.x <= -0.75) {
        orientationNew = UIInterfaceOrientationLandscapeRight;
    }
    else if (acceleration.y <= -0.75) {
        orientationNew = UIInterfaceOrientationPortrait;
    }
    else if (acceleration.y >= 0.75) {
        orientationNew = UIInterfaceOrientationPortraitUpsideDown;
    }
    else {
        // Consider same as last time
        return;
    }
    
    if (orientationNew == self.interfaceOrientation)
        return;
    
    self.interfaceOrientation = orientationNew;
}

#pragma mark - 判断视频帧方向
- (IFlyFaceDirectionType)faceImageOrientation {
    IFlyFaceDirectionType faceOrientation=IFlyFaceDirectionTypeLeft;
    BOOL isFrontCamera = self.videoCamera.cameraPosition == AVCaptureDevicePositionFront;
    switch (self.interfaceOrientation) {
        case UIDeviceOrientationPortrait:{//
            faceOrientation=IFlyFaceDirectionTypeLeft;
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:{
            faceOrientation=IFlyFaceDirectionTypeRight;
        }
            break;
        case UIDeviceOrientationLandscapeRight:{
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeUp:IFlyFaceDirectionTypeDown;
        }
            break;
        default:{//
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeDown:IFlyFaceDirectionTypeUp;
        }
            break;
    }
    
    return faceOrientation;
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    if (flag) {
        NSLog(@"录制完成");
        [self finishRecordBtnClick];
    }
    
}

#pragma mark - 懒加载

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.minimumInteritemSpacing = 5;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        CGFloat collectionH = (SCREEN_HEIGHT - SCREEN_WIDTH * 4 / 3) / 2;
        CGFloat itemWH = collectionH - 10;
        layout.itemSize = CGSizeMake(itemWH, itemWH);
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - collectionH, SCREEN_WIDTH, collectionH) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[FilterCell class] forCellWithReuseIdentifier:cellID];
    }
    return _collectionView;
}

@end
