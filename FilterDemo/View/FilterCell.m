//
//  FilterCell.m
//  FilterDemo
//
//  Created by wpsd on 2017/5/27.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "FilterCell.h"
#import "FilterModel.h"

@interface FilterCell ()

@property (strong, nonatomic) UIButton *btn;

@end

@implementation FilterCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btn.titleLabel.numberOfLines = 0;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.backgroundColor = UIColor.orangeColor;
        btn.userInteractionEnabled = NO;
        [self.contentView addSubview:btn];
        self.btn = btn;
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.btn.frame = self.bounds;
    
}

- (void)setFilterModel:(FilterModel *)filterModel {
    _filterModel = filterModel;
    
    [self.btn setTitle:filterModel.filterName forState:UIControlStateNormal];
    
}

@end
