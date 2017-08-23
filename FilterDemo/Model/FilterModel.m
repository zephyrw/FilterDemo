//
//  FilterModel.m
//  FilterDemo
//
//  Created by wpsd on 2017/5/27.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "FilterModel.h"

#import "FWNashvilleFilter.h"
#import "FWAmaroFilter.h"
#import "FWRiseFilter.h"
#import "FWHudsonFilter.h"
#import "FW1977Filter.h"
#import "FWValenciaFilter.h"
#import "FWXproIIFilter.h"
#import "FWWaldenFilter.h"
#import "FWLomofiFilter.h"
#import "FWInkwellFilter.h"
#import "FWSierraFilter.h"
#import "FWEarlybirdFilter.h"
#import "FWSutroFilter.h"
#import "FWToasterFilter.h"
#import "FWBrannanFilter.h"
#import "FWHefeFilter.h"

@implementation FilterModel

+ (instancetype)filterModelWithFilterGroup:(GPUImageFilterGroup *)filterGroup filterName:(NSString *)filterName {
    
    FilterModel *filterModel = [self new];
    filterModel.filterGroup = filterGroup;
    filterModel.filterName = filterName;
    return filterModel;
    
}

+ (NSMutableArray *)filters {
    NSMutableArray *filters = [NSMutableArray array];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[GPUImageFilterGroup new] filterName:@"原始"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWSierraFilter new] filterName:@"哥特风"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWRiseFilter new] filterName:@"彩虹瀑"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWValenciaFilter new] filterName:@"复古"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWHudsonFilter new] filterName:@"云端"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWXproIIFilter new] filterName:@"淡雅"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWWaldenFilter new] filterName:@"候鸟"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FW1977Filter new] filterName:@"粉红佳人"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWEarlybirdFilter new] filterName:@"古铜色"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWLomofiFilter new] filterName:@"一九OO"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWHefeFilter new] filterName:@"HEFE"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWToasterFilter new] filterName:@"TOSTER"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWBrannanFilter new] filterName:@"BRANNAN"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWSutroFilter new] filterName:@"移轴"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWInkwellFilter new] filterName:@"黑白"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[GPUImageMissEtikateFilter new] filterName:@"流年"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWNashvilleFilter new] filterName:@"碧波"]];
    [filters addObject:[FilterModel filterModelWithFilterGroup:[FWAmaroFilter new] filterName:@"经典"]];
//        [_filters addObject:[FilterModel filterModelWithFilterGroup:[GPUImageSoftEleganceFilter new] filterName:@"流年"]];
//        [_filters addObject:[FilterModel filterModelWithFilterGroup:[FWLordKelvinFilter new] filterName:@"上野"]];
//        [_filters addObject:[FilterModel filterModelWithFilterGroup:[GPUImageAmatorkaFilter new] filterName:@"优格"]];
    return filters;
}

@end
