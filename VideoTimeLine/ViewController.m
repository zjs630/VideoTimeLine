//
//  ViewController.m
//  VideoTimeLine
//
//  Created by ZhangJingshun on 2017/2/13.
//  Copyright © 2017年 zjs. All rights reserved.
//

#import "ViewController.h"
#import "SLRTSPTimeLineView.h"

#define D_CVR_DataTimeView_H    40
#define D_CVR_TimeLineView_H    52


@interface ViewController ()<CustomProgressDelegate>

@property (nonatomic, strong) SLRTSPTimeLineView *timeLineView; //视频播放时间轴
@property (nonatomic, strong) NSArray *videoInfoList; //存放时间轴视频信息，因视频录像可能因网络或停电等问题中断，所以视频录像是不连续的。
@property (nonatomic,assign) BOOL isPlaying;
@property (weak, nonatomic) IBOutlet UILabel *logLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addTimeLineView];
    [self loadData];
}

- (void)loadData{
    //因视频是分段存储的，所以每段时间必须有一个开始时间和一个结束时间。以下仅仅是测试数据。视频的真实数据需要做一次时间转换，
    //同时过滤非法数据（如跨天的数据，结束时间小于开始时间等）。
    NSNumber *number1 = [NSNumber numberWithDouble:(2*60*60)];//开始时间
    NSNumber *number2 = [NSNumber numberWithDouble:(4*60*60)];//结束时间
    NSNumber *number3 = [NSNumber numberWithDouble:(7*60*60)];//开始时间
    NSNumber *number4 = [NSNumber numberWithDouble:(12*60*60)];//结束时间
    NSNumber *number5 = [NSNumber numberWithDouble:(22*60*60)];//开始时间
    NSNumber *number6 = [NSNumber numberWithDouble:(24*60*60)];//结束时间
    
    NSArray *array = [NSArray arrayWithObjects:number1,number2,number3,number4,number5,number6, nil];
    self.timeLineView.progressSlider.times = array;

}

- (void)addTimeLineView{//跟张丽荣确认，加载完网络数据后才显示时间轴。
    if (self.timeLineView == nil) {//避免重复添加
        self.timeLineView = [[SLRTSPTimeLineView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-D_CVR_TimeLineView_H-60, self.view.frame.size.width, D_CVR_TimeLineView_H)];
        [self.timeLineView.playButton addTarget:self action:@selector(playOrPauseVedioButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.timeLineView.progressSlider.progressDelegate = self;
        [self.view addSubview:self.timeLineView];
    }
}

#pragma mark - 时间轴
/**
 时间轴 delegate方法
 */
- (void)timeLineStatusChange:(UIGestureRecognizerState)state{
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateBegan) {
        //self.disableUpdateTimeLine = YES; //时间轴的滑块，停止因视频播放器造成的移动。
    }
    else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled){
        SLCustomProgress *slider = self.timeLineView.progressSlider;
        //[self playSelectedVideoSection:slider.currentTime];//查找选择的那段视频，并seek到指定位置
        self.logLabel.text = [slider getWillPlayTimeLog];
        //self.disableUpdateTimeLine = NO;
    }
}

/**
 时间轴开始播放或者暂停操作
 */
- (void)playOrPauseVedioButtonPressed:(id)sender {
    
//    BOOL isPlaying = 视频是否正在播放;
    [_timeLineView changePlayStatus:!_isPlaying]; //改变按钮播放状态

    if (_isPlaying) {
        _isPlaying  = NO;
        self.logLabel.text = @"已经暂停播放";
    }
    else{
        _isPlaying = YES;
        self.logLabel.text = @"开始播放";

    }
}


#pragma mark - 旋转操作

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.view.window == nil) {//不显示的页面，不用旋转
        return;
    }
    
    self.timeLineView.frame = CGRectMake(0, size.height - D_CVR_TimeLineView_H, size.width, D_CVR_TimeLineView_H);
    SLCustomProgress *progressSlider = self.timeLineView.progressSlider;
    [progressSlider setTime:progressSlider.currentTime animated:NO];

}

@end
