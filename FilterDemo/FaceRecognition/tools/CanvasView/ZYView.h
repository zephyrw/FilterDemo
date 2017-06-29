//
//  scnView.h
//  FilterDemo
//
//  Created by wpsd on 2017/6/23.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

#define POINTS_KEY @"POINTS_KEY"
#define RECT_KEY   @"RECT_KEY"
#define RECT_ORI   @"RECT_ORI"


@interface ZYView : UIView

@property (nonatomic , strong) NSArray *arrPersons ;
@property (strong, nonatomic) GPUImageFilter *rotateFilter;

@end
