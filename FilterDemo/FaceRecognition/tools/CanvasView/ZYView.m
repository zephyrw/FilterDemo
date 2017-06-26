//
//  scnView.m
//  FilterDemo
//
//  Created by wpsd on 2017/6/23.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ZYView.h"

@interface ZYView ()<SCNSceneRendererDelegate>

@property (strong, nonatomic) SCNScene *myScene;
@property (strong, nonatomic) SCNNode *textNode;
@property (strong, nonatomic) SCNNode *cameraNode;
@property (strong, nonatomic) SCNView *scnView;
@property (strong, nonatomic) SCNRenderer *secondaryRenderer;
@property (strong, nonatomic) GPUImageTextureInput *textureInput;
@property (strong, nonatomic) EAGLContext *eaglContext;
@property (strong, nonatomic) dispatch_queue_t glRenderQueue;
@property (strong, nonatomic) dispatch_queue_t videoBuildingQueue;
@property (assign, nonatomic) GLuint outputTexture;
@property (assign, nonatomic) GLuint outputFramebuffer;
@property (assign, nonatomic) CGSize videoSize;

@end

@implementation ZYView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        EAGLSharegroup *group = [GPUImageContext sharedImageProcessingContext].context.sharegroup;
        self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:group];
        
        SCNView *scnView = [[SCNView alloc] initWithFrame:self.bounds];
        scnView.preferredFramesPerSecond = 60;
        scnView.autoenablesDefaultLighting = YES;
        scnView.allowsCameraControl = YES;
        scnView.eaglContext = self.eaglContext;
        scnView.backgroundColor = [UIColor clearColor];
        scnView.delegate = self;
        [self addSubview:scnView];
        self.scnView = scnView;
        
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
    
    self.textNode = [SCNNode node];
    self.textNode.geometry = [SCNText textWithString:@"Zephyr" extrusionDepth:0.5];
    self.textNode.position = SCNVector3Make(0, 0, -100);
    [self.myScene.rootNode addChildNode:self.textNode];
    
    self.cameraNode = [SCNNode node];
    self.cameraNode.camera = [SCNCamera camera];
    self.cameraNode.camera.automaticallyAdjustsZRange = YES;
    [self.myScene.rootNode addChildNode:self.cameraNode];
    
    
    self.scnView.scene = self.myScene;
    
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
        
        GLsizei width = (GLsizei)self.videoSize.width;
        GLsizei height = (GLsizei)self.videoSize.height;
        
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
        
        [self.secondaryRenderer renderAtTime:time];
        
        dispatch_sync(self.videoBuildingQueue, ^{
            [self.textureInput processTextureWithFrameTime:CMTimeMake(time, 100000)];
        });
        
    });
    
}

#pragma mark - SCNSceneRendererDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer didRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time {
    
    self.secondaryRenderer.scene = scene;
    self.secondaryRenderer.pointOfView = renderer.pointOfView;
    [self renderToFramebufferWithTime:time];
    
}

@end
