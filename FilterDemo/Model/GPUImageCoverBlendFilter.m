//
//  GPUImageCoverBlendFilter.m
//  FilterDemo
//
//  Created by wpsd on 2017/6/20.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "GPUImageCoverBlendFilter.h"

NSString *const kGPUImageCoverBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 base = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
     
     mediump float r;
     mediump float g;
     mediump float b;
     mediump float a;
     
     if (overlay.a == 1.0) {
         r = overlay.r * overlay.a;
         g = overlay.g * overlay.a;
         b = overlay.b * overlay.a;
         a = 1.0;
     }else if (overlay.a > 0.0) {
         
         if (overlay.r * base.a + base.r * overlay.a >= overlay.a * base.a) {
             r = overlay.a * base.a + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
         } else {
             r = overlay.r + base.r;
         }
         
         if (overlay.g * base.a + base.g * overlay.a >= overlay.a * base.a) {
             g = overlay.a * base.a + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
         } else {
             g = overlay.g + base.g;
         }
         
         if (overlay.b * base.a + base.b * overlay.a >= overlay.a * base.a) {
             b = overlay.a * base.a + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
         } else {
             b = overlay.b + base.b;
         }
         
         a = overlay.a + base.a - overlay.a * base.a;
         
     }else {
         r = base.r;
         g = base.g;
         b = base.b;
         a = base.a;
     }
     
     gl_FragColor = vec4(r, g, b, a);
 }
 );

@implementation GPUImageCoverBlendFilter

- (id)init {
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageCoverBlendFragmentShaderString])) {
        return nil;
    }
    
    return self;
}

@end
