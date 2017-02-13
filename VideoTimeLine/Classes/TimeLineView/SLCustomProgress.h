//
//  SLCustomProgress.h
//  SLProgressDemo
//
//  Created by ZhangJingshun on 15/5/25.
//  Copyright (c) 2015年 SengLed. All rights reserved.
//

#import <UIKit/UIKit.h>

#define Margin_Left_Right 10

@protocol CustomProgressDelegate <NSObject>
-(void)timeLineStatusChange:(UIGestureRecognizerState)state;
@end


@interface SLCustomProgress : UIControl

/** 滑块状态变化委托 */
//add by zjs
@property (weak) id<CustomProgressDelegate> progressDelegate;


/** 当前的时间 */
@property (assign, nonatomic, readonly) NSTimeInterval currentTime;

/** 播放时间段，数据个数必须是偶数，且满足相邻两个为一组，代表播放区域段的起始时间和结束时间 */
@property (strong, nonatomic) NSArray *times;



/** 设置时间，并指定是否需要以动画的形式 */
- (void)setTime:(NSTimeInterval) time animated:(BOOL)animated;


/**
 @return  返回将要播放时间的字符串
 */
- (NSString *)getWillPlayTimeLog;
@end
