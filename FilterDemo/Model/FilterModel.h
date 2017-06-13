//
//  FilterModel.h
//  FilterDemo
//
//  Created by wpsd on 2017/5/27.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

@interface FilterModel : NSObject

@property (strong, nonatomic) GPUImageFilterGroup *filterGroup;
@property (copy, nonatomic) NSString *filterName;

+ (instancetype)filterModelWithFilterGroup:(GPUImageFilterGroup *)filterGroup filterName:(NSString *)filterName;

+ (NSMutableArray *)filters;

@end
