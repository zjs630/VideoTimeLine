//
//  SLRTSPTimeLineView.h
//  snap
//
//  Created by ZhangJingshun on 15/3/23.
//  Copyright (c) 2015年 SengLed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLCustomProgress.h"

@interface SLRTSPTimeLineView : UIView
@property (assign,nonatomic) BOOL disableUpdateTimeLine;//禁止更新播放时间

@property (strong,nonatomic) UIButton *playButton;
@property (strong, nonatomic) UILabel *leftLabel;
@property (strong, nonatomic) UILabel *progressLabel;
//@property (strong, nonatomic) UISlider *progressSlider;
@property (strong, nonatomic) SLCustomProgress *progressSlider;


//- (void)refreshViewWith:(KxMovieDecoder *)decoder position:(NSUInteger)position;
/**
 改变播放按钮状态 开始或者暂停 YES:开始按钮 NO：暂定按钮
 */
- (void)changePlayStatus:(BOOL)isPlaying;

#pragma mark - 滑块
/**
 设置可以拖动滑块儿
 */
-(void)enableScrubber;

/**
 禁止滑块儿拖动
 */
-(void)disableScrubber;

#pragma mark - 按钮

/**
 运行播放暂停
 */
-(void)enablePlayerButtons;

/**
 禁止按下播放暂停
 */
-(void)disablePlayerButtons;


@end
