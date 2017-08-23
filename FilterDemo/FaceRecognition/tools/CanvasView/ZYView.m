//
//  scnView.m
//  FilterDemo
//
//  Created by wpsd on 2017/6/23.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ZYView.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface ZYView ()<SCNSceneRendererDelegate>

@property (strong, nonatomic) SCNScene *myScene;
@property (strong, nonatomic) SCNMaterial *imageMaterial;
@property (strong, nonatomic) SCNNode *geometryNode;
@property (strong, nonatomic) SCNNode *bigGeoNode;
@property (strong, nonatomic) SCNNode *pGeoNode;
@property (strong, nonatomic) SCNNode *textNode;
@property (strong, nonatomic) SCNNode *cameraNode;
@property (strong, nonatomic) SCNNode *cameraBoxNode;
@property (strong, nonatomic) SCNView *scnView;
@property (strong, nonatomic) SCNRenderer *secondaryRenderer;
@property (strong, nonatomic) EAGLContext *eaglContext;
@property (strong, nonatomic) dispatch_queue_t glRenderQueue;
@property (strong, nonatomic) dispatch_queue_t videoBuildingQueue;
@property (assign, nonatomic) GLuint outputTexture;
@property (assign, nonatomic) GLuint outputFramebuffer;
@property (assign, nonatomic) CGSize videoSize;
@property (strong, nonatomic) GPUImageTextureInput *textureInput;
@property (assign, nonatomic) CGPoint preMiddlePoint;
//@property (strong, nonatomic) SCNPlane *plane;
@property (strong, nonatomic) SCNTorus *torus;
@property (assign, nonatomic) CGPoint scnMiddlePoint;

@end

@implementation ZYView
{
    CGContextRef context;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        EAGLSharegroup *group = [GPUImageContext sharedImageProcessingContext].context.sharegroup;
        self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:group];
        
        self.secondaryRenderer = [SCNRenderer rendererWithContext:self.eaglContext options:nil];
        self.videoBuildingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.videoSize = CGSizeMake(480, 640);
        
        [self setupScene];
        [self setupOpenGL];
        
        self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

- (void)setupScene {
    
    self.myScene = [SCNScene scene];
    
    self.imageMaterial = [SCNMaterial material];
    self.imageMaterial.doubleSided = true;
    self.imageMaterial.locksAmbientWithDiffuse = YES;
    self.imageMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1);
    self.imageMaterial.diffuse.wrapS = SCNWrapModeRepeat;
//    self.imageMaterial.diffuse.contents = [UIImage imageNamed:@"007.jpg"];
    
    self.torus = [SCNTorus torusWithRingRadius:0 pipeRadius:10];
//    self.torus = [SCNTorus torusWithRingRadius:100 pipeRadius:10];
    self.torus.materials = @[self.imageMaterial];
    self.geometryNode = [SCNNode nodeWithGeometry:self.torus];
//    self.geometryNode = [SCNScene sceneNamed:@"art.scnassets/harf_circle.dae"].rootNode.clone;
    self.geometryNode.position = SCNVector3Make(0.0, 180, 0.0);
    
    SCNNode *bigGeoNode = [SCNNode node];
    bigGeoNode.position = SCNVector3Make(0.0, 0.0, 0.0);
    [bigGeoNode addChildNode:self.geometryNode];
    self.bigGeoNode = bigGeoNode;
    
    self.pGeoNode = [SCNNode node];
    self.pGeoNode.position = SCNVector3Make(0.0, 0.0, -800.0);
    [self.pGeoNode addChildNode:self.bigGeoNode];
    [self.myScene.rootNode addChildNode:self.pGeoNode];
    
//    SCNNode *fishNode = [SCNScene sceneNamed:@"art.scnassets/xiaochouyu.dae"].rootNode.clone;
//    fishNode.position = SCNVector3Make(0, 0, -1000);
//    fishNode.scale = SCNVector3Make(0.4, 0.4, 0.4);
//    fishNode.rotation = SCNVector4Make(0, -M_PI_2, 0, 1);
//    [self.myScene.rootNode addChildNode:fishNode];
    
    self.cameraNode = [SCNNode node];
    self.cameraNode.camera = [SCNCamera camera];
    self.cameraNode.camera.automaticallyAdjustsZRange = YES;
    self.cameraNode.camera.yFov = 72.0;
    self.cameraNode.position = SCNVector3Make(0, 0, 0);
    self.cameraNode.eulerAngles = SCNVector3Make(0.0, 0.0, 0.0);
    
    self.cameraBoxNode = [SCNNode node];
    [self.cameraBoxNode addChildNode:self.cameraNode];
    [self.myScene.rootNode addChildNode:self.cameraBoxNode];
    
    SCNView *scnView = [[SCNView alloc] initWithFrame:self.bounds];
    scnView.preferredFramesPerSecond = 60;
    scnView.autoenablesDefaultLighting = YES;
    scnView.allowsCameraControl = YES;
    scnView.eaglContext = self.eaglContext;
    scnView.backgroundColor = [UIColor clearColor];
    scnView.delegate = self;
    scnView.playing = YES;
    scnView.scene = self.myScene;
    self.scnView = scnView;
    [self addSubview:scnView];
    
}

- (void)setupOpenGL {
    
    self.glRenderQueue = [GPUImageContext sharedContextQueue];
    
    dispatch_sync(self.glRenderQueue, ^{
        
        EAGLContext *context = [EAGLContext currentContext];
        if (context != self.eaglContext) {
            [EAGLContext setCurrentContext:self.eaglContext];
        }
        
        glGenFramebuffers(1, &_outputFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, self.outputFramebuffer);
        
        glGenTextures(1, &_outputTexture);
        glBindTexture(GL_TEXTURE_2D, self.outputTexture);
        
    });
    
    self.textureInput = [[GPUImageTextureInput alloc] initWithTexture:self.outputTexture size:self.videoSize];
    
    self.rotateFilter = [GPUImageFilter new];
    [self.rotateFilter setInputRotation:kGPUImageFlipVertical atIndex:0];
    [self.textureInput addTarget:self.rotateFilter];
    
}

- (void)renderToFramebufferWithTime:(NSTimeInterval)time {
    
    dispatch_sync(self.glRenderQueue, ^{
        EAGLContext *context = [EAGLContext currentContext];
        if (self.eaglContext != context) {
            [EAGLContext setCurrentContext:self.eaglContext];
        }
        @synchronized(self.eaglContext) {
            GLsizei width = (GLsizei)(self.videoSize.width);
            GLsizei height = (GLsizei)(self.videoSize.height);
            
            glBindFramebuffer(GL_FRAMEBUFFER, self.outputFramebuffer);
            glBindTexture(GL_TEXTURE_2D, self.outputTexture);
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.outputTexture, 0); 
            
            glViewport(0, 0, width, height);
            
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glEnable(GL_DEPTH_TEST);
            
            [self.secondaryRenderer renderAtTime:time];
            
            dispatch_sync(self.videoBuildingQueue, ^{
                [self.textureInput processTextureWithFrameTime:CMTimeMake(time, 100000)];
            });
        }
        
    });
    
}

- (void)drawRect:(CGRect)rect {
    [self drawPointWithPoints:self.arrPersons];
}

-(void)drawPointWithPoints:(NSArray *)arrPersons{
    
    if (context) {
        CGContextClearRect(context, self.bounds) ;
    }
    context = UIGraphicsGetCurrentContext();
    
    double rotateZ = 0.0;
    double rotateY = 0.0;
    double rotateX = 0.0;
    //头部中点
    CGPoint midpoint = CGPointZero;
    //    CGFloat spacing = 60;
    
    for (NSDictionary *dicPerson in self.arrPersons) {
        
#pragma mark - 识别面部关键点
        /*
         识别面部关键点
         */
        if ([dicPerson objectForKey:POINTS_KEY]) {
#pragma mark - 取嘴角的点算头饰的旋转角度
            NSArray * strPoints = [dicPerson objectForKey:POINTS_KEY];
            //            NSLog(@"strPoints -> %@", strPoints);
            //右边鼻孔
            CGPoint  rightNostrilPoint = CGPointFromString(((NSString *)strPoints[2]));
//            CGContextAddEllipseInRect(context, CGRectMake(rightNostrilPoint.x - 1 , rightNostrilPoint.y - 1 , 2 , 2));
            //左边鼻孔
            CGPoint  leftNostrilPoint = CGPointFromString(((NSString *)strPoints[15]));
//            CGContextAddEllipseInRect(context, CGRectMake(leftNostrilPoint.x - 1 , leftNostrilPoint.y - 1 , 2 , 2));
            
            //右边嘴角
//            CGPoint  strPoint3 = CGPointFromString(((NSString *)strPoints[5]));
//            CGContextAddEllipseInRect(context, CGRectMake(strPoint3.x - 1 , strPoint3.y - 1 , 2 , 2));
            //左边嘴角
//            CGPoint strPoint4 = CGPointFromString(((NSString *)strPoints[20]));
//            CGContextAddEllipseInRect(context, CGRectMake(strPoint4.x - 1 , strPoint4.y - 1 , 2 , 2));
            
#pragma mark - 取眉毛的点算头部的位置
            
            // 左边眉毛左边点
//            CGPoint  otherPoint7 = CGPointFromString(((NSString *)strPoints[7]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint7.x - 1 , otherPoint7.y - 1 , 2 , 2));
            //左边眉毛中间点
            CGPoint  eyebrowsPoint1 = CGPointFromString(((NSString *)strPoints[16]));
//            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint1.x - 1 , eyebrowsPoint1.y - 1 , 2 , 2));
            
            //左边眉毛右边点
            CGPoint  eyebrowsPoint2 = CGPointFromString(((NSString *)strPoints[11]));
//            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint2.x - 1 , eyebrowsPoint2.y - 1 , 2 , 2));
            
            //右边眉毛中间点
            CGPoint  eyebrowsPoint3 = CGPointFromString(((NSString *)strPoints[17]));
//            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint3.x - 1 , eyebrowsPoint3.y - 1 , 2 , 2));
            
            //右边眉毛左边点
            CGPoint eyebrowsPoint4 = CGPointFromString(((NSString *)strPoints[18]));
//            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint4.x - 1 , eyebrowsPoint4.y - 1 , 2 , 2));
            
            // 右眉右边点
//            CGPoint  otherPoint13 = CGPointFromString(((NSString *)strPoints[13]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint13.x - 1 , otherPoint13.y - 1 , 2 , 2));
            
//            CGFloat midpointX  = (spacing *(eyebrowsPoint4.x + eyebrowsPoint2.x - eyebrowsPoint3.x - eyebrowsPoint1.x) / (eyebrowsPoint4.y + eyebrowsPoint2.y - eyebrowsPoint3.y - eyebrowsPoint1.y) + (eyebrowsPoint1.x + eyebrowsPoint3.x)) / 2;
//            CGFloat midpointY = eyebrowsPoint2.y - spacing;
            
            rotateZ = atan((eyebrowsPoint3.y - eyebrowsPoint1.y) / (eyebrowsPoint3.x - eyebrowsPoint1.x));
            if (eyebrowsPoint1.x >= eyebrowsPoint3.x) {
                rotateZ = M_PI + rotateZ;
            }
//            NSLog(@"rotation -> %f", rotation);
            
            CGFloat midpointX = (eyebrowsPoint2.x + eyebrowsPoint3.x + eyebrowsPoint1.x + eyebrowsPoint4.x) / 4;
            CGFloat midpointY = (eyebrowsPoint2.y + eyebrowsPoint3.y + eyebrowsPoint1.y + eyebrowsPoint4.y) / 4;
            
            // 右眼右边点
//            CGPoint  otherPoint0 = CGPointFromString(((NSString *)strPoints[0]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint0.x - 1 , otherPoint0.y - 1 , 2 , 2));
            // 右眼左边点
//            CGPoint  otherPoint1 = CGPointFromString(((NSString *)strPoints[1]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint1.x - 1 , otherPoint1.y - 1 , 2 , 2));
            // 左眼左边点
//            CGPoint  otherPoint3 = CGPointFromString(((NSString *)strPoints[3]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint3.x - 1 , otherPoint3.y - 1 , 2 , 2));
            // 嘴上方
            CGPoint  mouseUpPoint = CGPointFromString(((NSString *)strPoints[4]));
//            CGContextAddEllipseInRect(context, CGRectMake(mouseUpPoint.x - 1 , mouseUpPoint.y - 1 , 2 , 2));
            // 嘴下方
//            CGPoint  mouseDownPoint = CGPointFromString(((NSString *)strPoints[6]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint6.x - 1 , otherPoint6.y - 1 , 2 , 2));
            // 下巴
            CGPoint  chinPoint = CGPointFromString(((NSString *)strPoints[8]));
            chinPoint = chinPoint;
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint8.x - 1 , otherPoint8.y - 1 , 2 , 2));
//          左眼中心点
            CGPoint  leftEyeCenterPoint = CGPointFromString(((NSString *)strPoints[9]));
//            CGContextAddEllipseInRect(context, CGRectMake(leftEyeCenterPoint.x - 1 , leftEyeCenterPoint.y - 1 , 2 , 2));
//          右眼中心点
            CGPoint  rightEyeCenterPoint = CGPointFromString(((NSString *)strPoints[10]));
//            CGContextAddEllipseInRect(context, CGRectMake(rightEyeCenterPoint.x - 1 , rightEyeCenterPoint.y - 1 , 2 , 2));
            // 鼻子
            CGPoint  nosePoint = CGPointFromString(((NSString *)strPoints[12]));
//            CGContextAddEllipseInRect(context, CGRectMake(nosePoint.x - 1 , nosePoint.y - 1 , 2 , 2));
            // 左眼右边点
//            CGPoint  otherPoint14 = CGPointFromString(((NSString *)strPoints[14]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint14.x - 1 , otherPoint14.y - 1 , 2 , 2));
            // 嘴中心点
//            CGPoint  otherPoint19 = CGPointFromString(((NSString *)strPoints[19]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint19.x - 1 , otherPoint19.y - 1 , 2 , 2));
            
            midpoint = CGPointMake(midpointX, midpointY);
//            CGContextAddEllipseInRect(context, CGRectMake(midpoint.x - 1 , midpoint.y - 1 , 2 , 2));
            
            // rotate with Y anxle
            CGPoint raPoint = [self pedalPoint:leftEyeCenterPoint p2:rightEyeCenterPoint p3:midpoint];
            double rightDelta = sqrt(pow(rightEyeCenterPoint.x - raPoint.x, 2) + pow(rightEyeCenterPoint.y - raPoint.y, 2));
            double leftDelta = sqrt(pow(leftEyeCenterPoint.x - raPoint.x, 2) + pow(leftEyeCenterPoint.y - raPoint.y, 2));
            leftDelta = leftDelta == 0 ? 0.0000001 : leftDelta;
            //            NSLog(@"rightDelta: %f  leftDelta: %f", rightDelta, leftDelta);
            double scale = rightDelta / leftDelta;
            if (scale >= 1) {
                rotateY = atan(scale - 1);
            } else {
                rotateY = -atan(1 / scale - 1);
            }
//            NSLog(@"rotateY: %f", rotateY);
            
            CGPoint raUpPedalPoint = [self pedalPoint:leftNostrilPoint p2:rightNostrilPoint p3:nosePoint];
            CGPoint raDownPedalPoint = [self pedalPoint:leftNostrilPoint p2:rightNostrilPoint p3:mouseUpPoint];
            double upDelta = sqrt(pow(nosePoint.x - raUpPedalPoint.x, 2) + pow(nosePoint.y - raUpPedalPoint.y, 2));
            double downDelta = sqrt(pow(mouseUpPoint.x - raDownPedalPoint.x, 2) + pow(mouseUpPoint.y - raDownPedalPoint.y, 2)) - 3.5;
            downDelta = downDelta == 0 ? 0.0000001 : downDelta;
            double upDownScale = upDelta / downDelta;
            if (scale >= 1) {
                rotateX = atan(upDownScale - 1);
            } else {
                rotateX = -atan(1 / upDownScale - 1);
            }
            rotateX /= 2;
            
        }
        if (sqrt(powf(midpoint.x - self.preMiddlePoint.x, 2) + powf(midpoint.y - self.preMiddlePoint.y, 2)) <= 2) {
            return;
        }
        self.preMiddlePoint = midpoint;
        BOOL isOriRect = NO;
        if ([dicPerson objectForKey:RECT_ORI]) {
            isOriRect=[[dicPerson objectForKey:RECT_ORI] boolValue];
        }
        
        if ([dicPerson objectForKey:RECT_KEY]) {
            
            CGRect rect = CGRectFromString([dicPerson objectForKey:RECT_KEY]);
//            CGContextAddRect(context, rect);
            
            if (self.geometryNode) {
                CGFloat scale = (rect.size.width / 180);
                self.scnMiddlePoint = [self convertUIPointToSCNPoint:midpoint];
                self.pGeoNode.position = SCNVector3Make(self.scnMiddlePoint.x, self.scnMiddlePoint.y, -800);
                self.geometryNode.position = SCNVector3Make(0, self.torus.pipeRadius * 2 + 180, 0);
                self.geometryNode.scale = SCNVector3Make(scale, scale, scale);
                self.geometryNode.rotation = SCNVector4Make(0, 1, 0, rotateY);
                self.bigGeoNode.rotation = SCNVector4Make(0, 0, 1, -rotateZ);
                self.pGeoNode.rotation = SCNVector4Make(1, 0, 0, -rotateX);
            }
        }
    }
    
    [[UIColor greenColor] set];
    CGContextSetLineWidth(context, 2);
    CGContextStrokePath(context);
}

- (CGPoint)convertUIPointToSCNPoint:(CGPoint)point {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    return CGPointMake(point.x - width / 2, height / 2 - point.y);
}

- (CGPoint)pedalPoint:(CGPoint)p1 p2:(CGPoint )p2 p3:(CGPoint)p0 {
    
    float A = p2.y - p1.y;
    float B = p1.x - p2.x;
    float C = p2.x * p1.y - p1.x * p2.y;
    
    float x = (B * B * p0.x - A * B * p0.y - A * C) / (A * A + B * B);
    float y = (-A * B * p0.x + A * A * p0.y - B * C)/(A * A + B * B);
    
    //点到直线距离
//    float d = (A * x0.x + B * x0.y + C) / sqrt(A * A + B * B);
    
    CGPoint ptCross = CGPointMake(x, y);
    return ptCross;
}


#pragma mark - SCNSceneRendererDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer didRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time {
    
    self.secondaryRenderer.scene = scene;
    self.secondaryRenderer.pointOfView = renderer.pointOfView;
    [self renderToFramebufferWithTime:time];
    
}

@end
