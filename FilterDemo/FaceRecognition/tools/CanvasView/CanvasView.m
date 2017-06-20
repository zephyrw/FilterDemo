//
//  CanvasView.m
//  Created by sluin on 15/7/1.
//  Copyright (c) 2015年 SunLin. All rights reserved.
//

#import "CanvasView.h"

@interface CanvasView ()

//头部贴图
@property (nonatomic,strong) UIImageView * headMapView;
//眼睛贴图
@property (nonatomic,strong) UIImageView * eyesMapView;
//鼻子贴图
@property (nonatomic,strong) UIImageView * noseMapView;
//嘴巴贴图
@property (nonatomic,strong) UIImageView * mouthMapView;
//面部贴图
@property (nonatomic,strong) UIImageView * facialTextureMapView;

@end

@implementation CanvasView{
    CGContextRef context ;
}

-(UIImageView *) headMapView{
    if(_headMapView == nil){
        
        _headMapView = [[UIImageView alloc] init];
        [self addSubview:_headMapView];
        
    }
    return _headMapView;
}


-(void) setHeadMap:(UIImage *)headMap{
    if (_headMap != headMap) {
        _headMap = headMap;
        self.headMapView.image = _headMap;
        
    }
}

- (void)drawRect:(CGRect)rect {
    [self drawPointWithPoints:self.arrPersons] ;

}

-(void)drawPointWithPoints:(NSArray *)arrPersons{
    
    if (context) {
        CGContextClearRect(context, self.bounds) ;
    }
    context = UIGraphicsGetCurrentContext();

    double rotation = 0.0;
    //头部中点
    CGPoint midpoint = CGPointZero;
    CGFloat spacing = 60;
    
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
            CGPoint  strPoint1 = CGPointFromString(((NSString *)strPoints[2]));
            CGContextAddEllipseInRect(context, CGRectMake(strPoint1.x - 1 , strPoint1.y - 1 , 2 , 2));
            //左边鼻孔
            CGPoint  strPoint2 = CGPointFromString(((NSString *)strPoints[15]));
            CGContextAddEllipseInRect(context, CGRectMake(strPoint2.x - 1 , strPoint2.y - 1 , 2 , 2));
            
            //右边嘴角
            CGPoint  strPoint3 = CGPointFromString(((NSString *)strPoints[5]));
            CGContextAddEllipseInRect(context, CGRectMake(strPoint3.x - 1 , strPoint3.y - 1 , 2 , 2));
            //左边嘴角
            CGPoint strPoint4 = CGPointFromString(((NSString *)strPoints[20]));
            CGContextAddEllipseInRect(context, CGRectMake(strPoint4.x - 1 , strPoint4.y - 1 , 2 , 2));
            
            rotation = atan((strPoint3.x + strPoint4.x - strPoint1.x - strPoint2.x) / (strPoint3.y + strPoint4.y - strPoint1.y - strPoint2.y));
            if (strPoint4.x >= strPoint3.x) {
                rotation = M_PI + rotation;
            }
//            NSLog(@"rotation -> %f", rotation);
            
#pragma mark - 取眉毛的点算头部的位置
            
            // 左边眉毛左边点
            CGPoint  otherPoint7 = CGPointFromString(((NSString *)strPoints[7]));
            CGContextAddEllipseInRect(context, CGRectMake(otherPoint7.x - 1 , otherPoint7.y - 1 , 2 , 2));
            //左边眉毛中间点
            CGPoint  eyebrowsPoint1 = CGPointFromString(((NSString *)strPoints[16]));
            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint1.x - 1 , eyebrowsPoint1.y - 1 , 2 , 2));
            
            //左边眉毛右边点
            CGPoint  eyebrowsPoint2 = CGPointFromString(((NSString *)strPoints[11]));
            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint2.x - 1 , eyebrowsPoint2.y - 1 , 2 , 2));
            
            //右边眉毛中间点
            CGPoint  eyebrowsPoint3 = CGPointFromString(((NSString *)strPoints[17]));
            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint3.x - 1 , eyebrowsPoint3.y - 1 , 2 , 2));
            
            //右边眉毛左边点
            CGPoint eyebrowsPoint4 = CGPointFromString(((NSString *)strPoints[18]));
            CGContextAddEllipseInRect(context, CGRectMake(eyebrowsPoint4.x - 1 , eyebrowsPoint4.y - 1 , 2 , 2));
            
            // 右眉右边点
            CGPoint  otherPoint13 = CGPointFromString(((NSString *)strPoints[13]));
            CGContextAddEllipseInRect(context, CGRectMake(otherPoint13.x - 1 , otherPoint13.y - 1 , 2 , 2));
            
//            CGFloat midpointX  = (spacing *(eyebrowsPoint4.x + eyebrowsPoint2.x - eyebrowsPoint3.x - eyebrowsPoint1.x) / (eyebrowsPoint4.y + eyebrowsPoint2.y - eyebrowsPoint3.y - eyebrowsPoint1.y) + (eyebrowsPoint1.x + eyebrowsPoint3.x)) / 2;
//            CGFloat midpointY = eyebrowsPoint2.y - spacing;
            
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
//            CGPoint  otherPoint4 = CGPointFromString(((NSString *)strPoints[4]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint4.x - 1 , otherPoint4.y - 1 , 2 , 2));
            // 嘴下方
//            CGPoint  otherPoint6 = CGPointFromString(((NSString *)strPoints[6]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint6.x - 1 , otherPoint6.y - 1 , 2 , 2));
            // 下巴
            CGPoint  otherPoint8 = CGPointFromString(((NSString *)strPoints[8]));
            CGContextAddEllipseInRect(context, CGRectMake(otherPoint8.x - 1 , otherPoint8.y - 1 , 2 , 2));
            // 左眼中心点
//            CGPoint  otherPoint9 = CGPointFromString(((NSString *)strPoints[9]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint9.x - 1 , otherPoint9.y - 1 , 2 , 2));
            // 右眼中心点
//            CGPoint  otherPoint10 = CGPointFromString(((NSString *)strPoints[10]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint10.x - 1 , otherPoint10.y - 1 , 2 , 2));
            // 鼻子
            CGPoint  otherPoint12 = CGPointFromString(((NSString *)strPoints[12]));
            CGContextAddEllipseInRect(context, CGRectMake(otherPoint12.x - 1 , otherPoint12.y - 1 , 2 , 2));
            // 左眼右边点
//            CGPoint  otherPoint14 = CGPointFromString(((NSString *)strPoints[14]));
//            CGContextAddEllipseInRect(context, CGRectMake(otherPoint14.x - 1 , otherPoint14.y - 1 , 2 , 2));
            // 嘴中心点
            CGPoint  otherPoint19 = CGPointFromString(((NSString *)strPoints[19]));
            CGContextAddEllipseInRect(context, CGRectMake(otherPoint19.x - 1 , otherPoint19.y - 1 , 2 , 2));
            
            midpoint = CGPointMake(midpointX, midpointY);
            CGContextAddEllipseInRect(context, CGRectMake(midpoint.x - 1 , midpoint.y - 1 , 2 , 2));
        }
        
        BOOL isOriRect=NO;
        if ([dicPerson objectForKey:RECT_ORI]) {
            isOriRect=[[dicPerson objectForKey:RECT_ORI] boolValue];
        }
        
        if ([dicPerson objectForKey:RECT_KEY]) {
            
            CGRect rect=CGRectFromString([dicPerson objectForKey:RECT_KEY]);
            if (self.headMap){
                CGFloat scale =  (rect.size.width / self.headMap.size.width) + 0.3;
                CGFloat headMapViewW = scale * self.headMap.size.width;
                CGFloat headmapViewH = scale * self.headMap.size.height;
                
                CGRect frame  =  CGRectMake(midpoint.x - (headMapViewW * 0.5), midpoint.y - headmapViewH + 20, headMapViewW, headmapViewH);
                
                self.headMapView.frame = frame;
                self.headMapView.bounds = CGRectMake(0, 0, headMapViewW, headmapViewH);
                
                self.headMapView.layer.anchorPoint = CGPointMake(0.5, 1);
                self.headMapView.transform = CGAffineTransformMakeRotation(-rotation);
                
            }
        }
    }

    [[UIColor greenColor] set];
    CGContextSetLineWidth(context, 2);
    CGContextStrokePath(context);
}

@end
