//
//  SLRTSPTimeLineView.m
//  snap
//
//  Created by ZhangJingshun on 15/3/23.
//  Copyright (c) 2015年 SengLed. All rights reserved.
//

#import "SLRTSPTimeLineView.h"
#import "SLCustomProgress.h"

#define I_TimeLineView_Play     @"bt_play"
#define I_TimeLineView_Pause    @"bt_pause"


@interface SLRTSPTimeLineView ()

@property (strong,nonatomic) UIView *maskLayer;


@end

@implementation SLRTSPTimeLineView


- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        //半透明遮罩层//覆盖在视频上，时间轴的底色
        self.maskLayer = [[UIView alloc] initWithFrame:self.bounds];
        self.maskLayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.maskLayer.backgroundColor = [UIColor whiteColor];
        self.maskLayer.alpha = 0.3;
        [self addSubview:_maskLayer];
        //播放暂停按钮
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playButton.frame = CGRectMake(0, 0, 44, frame.size.height);
        self.playButton.backgroundColor = [UIColor clearColor];//
        [self.playButton setImage:[UIImage imageNamed:I_TimeLineView_Play] forState:UIControlStateNormal];
        [self addSubview:_playButton];
        //进度条和时间轴
        self.progressSlider = [[SLCustomProgress alloc] initWithFrame:CGRectMake(44-Margin_Left_Right, 0, frame.size.width-(44-Margin_Left_Right), frame.size.height)];
        self.progressSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.progressLabel.hidden = YES;
        [self addSubview:_progressSlider];
    }
    
    return self;
    
}

#pragma mark - 改变按钮状态

- (void)changePlayStatus:(BOOL)isPlaying{
    if (isPlaying == NO) {//如果没有播放，显示开始播放按钮
        [self.playButton setImage:[UIImage imageNamed:I_TimeLineView_Play] forState:UIControlStateNormal];
    }
    else{
        [self.playButton setImage:[UIImage imageNamed:I_TimeLineView_Pause] forState:UIControlStateNormal];
    }
}



#pragma mark - 滑块儿控制
-(void)enableScrubber {
    self.progressSlider.enabled = YES;
}

-(void)disableScrubber {
    self.progressSlider.enabled = NO;
}


#pragma mark - 开始播放按钮控制
-(void)enablePlayerButtons {
    self.playButton.enabled = YES;
}

-(void)disablePlayerButtons {
    self.playButton.enabled = NO;
}

@end
