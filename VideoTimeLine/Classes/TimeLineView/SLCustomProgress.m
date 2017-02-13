//
//  SLCustomProgress.m
//  SLProgressDemo
//
//  Created by ZhangJingshun on 15/5/25.
//  Copyright (c) 2015年 SengLed. All rights reserved.
//

#import "SLCustomProgress.h"
#import <CoreText/CoreText.h>
#import "SLSliderTimeLineView.h"

#define ONE_DAY (24 * 60 * 60)
#define ANIMATED 1
#define TimeLineWidth (self.bounds.size.width - Margin_Left_Right - Margin_Left_Right)

/** 根据十六进制a，r，g，b三原色和透明度生成对应的颜色值 */
#define SL_HEX_COLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0 alpha:((c>>24)&0xFF)/255.0]

@interface SLCustomProgress ()


/** 长按事件开始时的触摸点 */
@property (assign, nonatomic) CGPoint sliderLongPressStartPoint;
/** 长按事件结束时的触摸点 */
@property (assign, nonatomic) CGPoint endPoint;
/** 移动时的触摸点 */
@property (assign, nonatomic) CGPoint movePoint;

/** 进度条是否打开 */
@property (assign, nonatomic) BOOL isOpen;
/** 打开进度条时的时间 */
@property (assign, nonatomic) NSTimeInterval openTime;



/** 进度条距离控件顶部的距离 */
@property (assign, nonatomic) CGFloat progressTop;
/** 滑块View */
@property (strong, nonatomic) UIView *slider;
/** 滑块宽度 */
@property (assign, nonatomic) CGFloat sliderW;


@property (assign, nonatomic) NSTimeInterval startOpenTime;
@property (assign, nonatomic) NSTimeInterval openFade;
@property (assign, nonatomic) NSTimeInterval startCloseTime;
@property (assign, nonatomic) NSTimeInterval closeFade;

/** 动画的进度 */
@property (assign, nonatomic) CGFloat progress;

@property (assign, nonatomic) CGFloat overScreenLeft;//超出绘制时间轴左边的部分
@property (assign, nonatomic) CGFloat overScreenRight;//超出绘制时间轴右边的部分
@property (assign, nonatomic) CGFloat expandWidth;//拉伸后的宽度，默认展开一个小时，最终长度为：TimeLineWidth*24

@property (strong, nonatomic) UIColor *progressColor;
@property (strong, nonatomic) UIColor *progressValidColor;//有效的进度条颜色
@property (strong, nonatomic) UIColor *validBgColor;//有效的视频背景色

@end

@implementation SLCustomProgress


#pragma mark- 初始化
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initParam];
        [self initView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initParam];
        [self initView];
    }
    return self;
}

- (void)initView {
    [self setBackgroundColor:[UIColor clearColor]];
    
    self.slider = [[SLSliderTimeLineView alloc] initWithFrame:CGRectMake(0, 0, self.sliderW, self.frame.size.height)];
    [self addSubview:self.slider];
    
    [self moveSliderWithTime];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    [self.slider addGestureRecognizer:pan];
    // 添加长按事件
    UILongPressGestureRecognizer * longPressGr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    longPressGr.minimumPressDuration = 0.5;//设置为默认值，设为1.0的话，时间有些长。
    [self.slider addGestureRecognizer:longPressGr];
}

- (void)initParam {
    self.progressTop = 14;
    self.sliderW = 30;
    self.progressColor = SL_HEX_COLOR(0xff000000);
    self.progressValidColor = SL_HEX_COLOR(0xfff39b63);
    self.validBgColor = SL_HEX_COLOR(0x80f39b63);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self calculateOverScreen];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self calculateOverScreen];
    [self setNeedsDisplay];
}

#pragma mark- 长按事件触发
- (void)longPressAction:(UILongPressGestureRecognizer *)gesture {

    //FIXME:如果视频没有播放，long press，可以不起作用，根据需求自己添加。
    //    if(视频没有播放){
    //        return;
    //    }
    
    if(gesture.state == UIGestureRecognizerStateBegan) {
        self.sliderLongPressStartPoint = self.slider.center;
        self.openTime = self.currentTime;
        // 长按事件触发，展开进度条
        [self startOpen];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled){
        self.endPoint = [gesture locationInView:self];
        // 长按事件结束，关闭进度条
        [self startClose];
        [self setTime:self.currentTime animated:YES];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        self.movePoint = [gesture locationInView:self];
        [self moveSliderWithPoint];
    }
    [self.progressDelegate timeLineStatusChange:gesture.state];

}

#pragma mark- 拖拽事件
- (void)panAction:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.movePoint = [gesture locationInView:self];
        [self moveSliderWithPoint];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled){
        //如果时间轴滑动到后面没有视频的位置，从最后一段播放视频。需求已经确认。 add by zjs
        NSInteger tCounter = [self.times count];
        if (tCounter>=2) {
            NSTimeInterval endT = [self.times[tCounter-1] doubleValue];
            if (self.currentTime>endT && self.currentTime < ONE_DAY) {
                _currentTime = [self.times[tCounter-2] doubleValue];
            }
            else{
                _currentTime = [self checkLegal:self.currentTime];
            }
        }

        [self setTime:self.currentTime animated:YES];
    }
    
    [self.progressDelegate timeLineStatusChange:gesture.state];
    
}

#pragma mark- 动画
#pragma mark 启动动画
- (void)startOpen {
    if (!self.isOpen) {
        self.isOpen = YES;
        self.startOpenTime = [[NSDate date] timeIntervalSince1970];
        [self doOpen];
    }
}

- (void)doOpen {
    if (self.isOpen) {
        NSTimeInterval intervalTime = [[NSDate date] timeIntervalSince1970] - self.startOpenTime;
        if (intervalTime > ANIMATED) {
            self.openFade = 1;
        } else {
            self.openFade = [self interpolator:intervalTime/ANIMATED];
        }
        if (self.openFade >= 1) {
            self.openFade = 1;
        }
        self.progress = self.openFade;
        [self calculateOverScreen];
        [self setNeedsDisplay];
        
        if (self.openFade < 1) {
            [self performSelector:@selector(doOpen) withObject:nil afterDelay:0.02];
        }
    }
}

#pragma mark 关闭动画
- (void)startClose {
    if (self.isOpen) {
        self.isOpen = NO;
        self.startCloseTime = [[NSDate date] timeIntervalSince1970];
        [self doClose];
    }
}

- (void)doClose {
    if (!self.isOpen) {
        NSTimeInterval intervalTime = [[NSDate date] timeIntervalSince1970] - self.startCloseTime;
        if (intervalTime > ANIMATED) {
            self.closeFade = 1;
        } else {
            self.closeFade = [self interpolator:intervalTime/ANIMATED];
        }
        self.closeFade = self.openFade - self.closeFade;
        if (self.closeFade <= 0) {
            self.closeFade = 0;
        }
        self.progress = self.closeFade;
        [self calculateOverScreen];
        [self setNeedsDisplay];
        
        if (self.closeFade > 0) {
           [self performSelector:@selector(doClose) withObject:nil afterDelay:0.02];
        }
    }
}

#pragma mark 

- (void)calculateOverScreen {
    self.expandWidth = TimeLineWidth + self.progress * 23 * TimeLineWidth;
    self.overScreenLeft = ((self.sliderLongPressStartPoint.x - Margin_Left_Right) / TimeLineWidth ) * self.expandWidth - (self.sliderLongPressStartPoint.x - Margin_Left_Right);
    self.overScreenRight = self.expandWidth - TimeLineWidth - self.overScreenLeft;
    if (self.overScreenRight<TimeLineWidth/2) {//避免按下后不能查看最后面的视频
        self.overScreenRight = 0;
        self.overScreenLeft = self.expandWidth-TimeLineWidth;
    }
}

- (double)interpolator:(double)current {
    return (current * current) * (3 - 2 * (current));
}


#pragma mark 设置time
- (void)setTime:(NSTimeInterval)time animated:(BOOL)animated {
    if (time >= ONE_DAY) {
        time = ONE_DAY-1;
    }
    if (time<0) {
        time =0;
    }
    //time = [self checkLegal:time]; 注释代码 by zjs
    _currentTime = time;
    if (animated) {
        self.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.5 animations:^{
            [self moveSliderWithTime];
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    } else {
        [self moveSliderWithTime];
    }
}

#pragma mark 根据时间来调整滑块
- (void)moveSliderWithTime {
    CGFloat sliderCenterX = (int)(self.currentTime / ONE_DAY * TimeLineWidth + Margin_Left_Right + 0.5);//＋0.5代表四舍五入
    self.slider.center = CGPointMake(sliderCenterX, self.slider.center.y);
}

#pragma mark 根据滑动点来调整
- (void)moveSliderWithPoint {
    CGFloat centerX = self.movePoint.x;
//    NSLog(@"%f",centerX);
    if (centerX < Margin_Left_Right) {
        centerX = Margin_Left_Right;
    } else if (centerX > TimeLineWidth + Margin_Left_Right){
        centerX = TimeLineWidth+Margin_Left_Right;
    }
    [self.slider setCenter:CGPointMake(centerX , self.slider.center.y)];
    
    if (!self.isOpen) {
        _currentTime = (centerX-Margin_Left_Right) / TimeLineWidth * ONE_DAY;
    } else {
        _currentTime = (self.movePoint.x - Margin_Left_Right + _overScreenLeft)/_expandWidth * ONE_DAY;

    }

    //[self printLogTest]; //打印滑动的时间
}

#pragma mark 检测当前拖动的时间是否合法，不合法需要回归到指定位置
- (NSTimeInterval)checkLegal:(NSTimeInterval) time {
    if (self.times.count == 0) {
        return time;
    }
    
    BOOL isLegal = NO;
    NSTimeInterval lastTime = -1;
    
    for (int i = 0; i < self.times.count; i++) {
        NSNumber *startNumber = [self.times objectAtIndex:i++];
        NSTimeInterval start = [startNumber doubleValue];
        if (start > ONE_DAY) {
            start = (int)start % ONE_DAY;
        }
        
        if (lastTime == -1) {
            lastTime = start;
        }
        
        if (time < start) {
            lastTime = start;
            break;
        }
        
        NSNumber *endNumber = [self.times objectAtIndex:i];
        NSTimeInterval end = [endNumber doubleValue];
        
        if (end > ONE_DAY) {
            end = (int)end % ONE_DAY;
        }
        
        if (time < end) {
            isLegal = YES;
            break;
        }
    }
    
    if (!isLegal) {
        time = lastTime;
    }
    
    return time;
}

- (void)setTimes:(NSArray *)times {
    _times = times;
    _currentTime = [self checkLegal:self.currentTime];
    [self setTime:self.currentTime animated:NO];
}

- (void)printLogTest {
    int h = self.currentTime / (60 * 60);
    int ms = (int)self.currentTime % (60 * 60);
    int m = ms / 60;
    int s = ms % 60;
    NSLog(@"videoWillPlay 时间为: %.2d:%.2d:%.2d",h,m,s);
}

- (NSString *)getWillPlayTimeLog {
    int h = self.currentTime / (60 * 60);
    int ms = (int)self.currentTime % (60 * 60);
    int m = ms / 60;
    int s = ms % 60;
    NSString *time = [NSString stringWithFormat:@"videoWillPlay 时间为: %.2d:%.2d:%.2d",h,m,s];
    return time;
}

#pragma mark- 绘制
- (void)drawRect:(CGRect)rect {
    UIImage *image = [self drawTime];
    [image drawAsPatternInRect:rect];
}

#pragma mark 绘制时间
- (UIImage*)drawTime {
    
    CGFloat w = self.expandWidth;
    CGFloat y = self.progressTop;
    
    CGFloat clipX = self.overScreenLeft;
    
    // 创建绘图上下文
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    int xxx = clipX > 0 ? 0:Margin_Left_Right;
    // 绘制直线
    UIBezierPath* bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(xxx,y,w,2)];
    [self.progressColor setFill];
    [bezierPath fill];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 绘制半小时分割线
    NSInteger count = 48;
    CGFloat x = 0;
    for (int i = 0; i <= count; i++) {
        x = (int)(i * (w/count) - clipX + 0.5);
        CGContextMoveToPoint(context, x + Margin_Left_Right, y);
        CGContextAddLineToPoint(context, x + Margin_Left_Right, y + 8);
        
        CGFloat alpha = 1;
//        if (self.progress >= 0.1 && self.progress <= 0.6) {
//            alpha = (1 - (self.progress - 0.1)/0.5);
//        } else if (self.progress > 0.6) {
//            alpha = 0;
//        }
        alpha = (1 - self.progress);
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        [color set];
        
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    // 绘制每小时分割线
    count = 24;
    for (int i = 0; i <= count; i++) {
        x = (int)(i * (w/count) - clipX + 0.5);
        CGContextMoveToPoint(context, x + Margin_Left_Right, y);
        CGContextAddLineToPoint(context, x + Margin_Left_Right, y + 12);
        
        CGFloat alpha = 1;
        alpha = (1 - self.progress);
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        [color set];
        
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    // 绘制每两小时分割线
    count = 12;
    for (int i = 0; i <= count; i++) {
        x = (int)(i * (w/count) - clipX + 0.5);
        CGContextMoveToPoint(context, x + Margin_Left_Right, y);
        CGContextAddLineToPoint(context, x + Margin_Left_Right, y + 16);
        
        CGFloat alpha = 1;
        alpha = (1 - self.progress);
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        [color set];
        
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    // 绘制每六小时文字
    count = 4;
    NSString *strFormat = @"%.2d:00";
    for (int i = 0; i <= count; i++) {
        int intFormat = i * 6;
        NSString *str = [NSString stringWithFormat:strFormat,intFormat];
        NSMutableAttributedString *mabstring = [[NSMutableAttributedString alloc] initWithString:str];
        
        CGFloat alpha = 1;
        alpha = (1 - self.progress);
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        
        [mabstring beginEditing];
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:(id)color.CGColor forKey:(id)kCTForegroundColorAttributeName];
        [mabstring addAttributes:attributes range:NSMakeRange(0, str.length)];
        [mabstring endEditing];
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mabstring);
        CGMutablePathRef path = CGPathCreateMutable();
        
        x = i * (w/count);
        if (i != 0 && i != count) {
            x -= 15;
        }
        
        if (i == count) {
            x -= 30;
        }
        x = (int)(x - clipX + 0.5);
        CGPathAddRect(path, NULL ,CGRectMake(x + Margin_Left_Right, -(y + 20) ,self.bounds.size.width , self.bounds.size.height));
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        //获取当前(View)上下文以便于之后的绘画，这个是一个离屏。
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix(context , CGAffineTransformIdentity);
        //压栈，压入图形状态栈中.每个图形上下文维护一个图形状态栈，并不是所有的当前绘画环境的图形状态的元素都被保存。图形状态中不考虑当前路径，所以不保存
        //保存现在得上下文图形状态。不管后续对context上绘制什么都不会影响真正得屏幕。
        CGContextSaveGState(context);
        //x，y轴方向移动
        CGContextTranslateCTM(context , 0 ,self.bounds.size.height);
        //缩放x，y轴方向缩放，－1.0为反向1.0倍,坐标系转换,沿x轴翻转180度
        CGContextScaleCTM(context, 1.0 ,-1.0);
        CTFrameDraw(frame,context);
        
        CGContextRestoreGState(context);
        CGPathRelease(path);
        CFRelease(framesetter);
        CFRelease(frame);
    }
    
    
    // 绘制每分钟的分割线
    count = 1440;
    for (int i = 0; i <= count; i++) {
        x = (int)(i * (w/count) - clipX + 0.5);
        CGContextMoveToPoint(context, x + Margin_Left_Right, y);
        CGContextAddLineToPoint(context, x + Margin_Left_Right, y + 8);
        
        CGFloat alpha = 0;
        alpha = self.progress;
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        [color set];
        
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    // 绘制每五分钟的分割线
    count = 288;
    for (int i = 0; i <= count; i++) {
        x = (int)(i * (w/count) - clipX + 0.5);
        CGContextMoveToPoint(context, x + Margin_Left_Right, y);
        CGContextAddLineToPoint(context, x + Margin_Left_Right, y + 12);
        
        CGFloat alpha = 0;
        alpha = self.progress;
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        [color set];
        
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    // 绘制每十分时分割线
    count = 144;
    for (int i = 0; i <= count; i++) {
        x = (int)(i * (w/count) - clipX + 0.5);
        
        CGContextMoveToPoint(context, x + Margin_Left_Right, y);
        CGContextAddLineToPoint(context, x + Margin_Left_Right, y + 16);
        
        CGFloat alpha = 0;
        alpha = self.progress;
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        [color set];
        
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    // 绘制每十分时分割线文字
    count = 144;
    for (int i = 0; i <= count; i++) {
        int intFormat = i;
        intFormat %= 6;
        
        NSString *str = [NSString stringWithFormat:@"%.2d:%d0",i/6,intFormat];
        NSMutableAttributedString *mabstring = [[NSMutableAttributedString alloc] initWithString:str];
        
        CGFloat alpha = 0;
        alpha = self.progress;
        UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
        
        [mabstring beginEditing];
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:(id)color.CGColor forKey:(id)kCTForegroundColorAttributeName];
        [mabstring addAttributes:attributes range:NSMakeRange(0, str.length)];
        [mabstring endEditing];
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mabstring);
        CGMutablePathRef path = CGPathCreateMutable();
        
        
        x = i * (w/count);
        if (i == 0) {
            x += 1;
        }
        
        if (i != 0 && i != count) {
            x -= 15;
        }
        else if (i == count) {
            x -= 30;
        }
        x = (int)(x - clipX + 0.5);
        CGPathAddRect(path, NULL ,CGRectMake(x + Margin_Left_Right, -(y + 20) ,self.bounds.size.width , self.bounds.size.height));
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        //获取当前(View)上下文以便于之后的绘画，这个是一个离屏。
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix(context , CGAffineTransformIdentity);
        //压栈，压入图形状态栈中.每个图形上下文维护一个图形状态栈，并不是所有的当前绘画环境的图形状态的元素都被保存。图形状态中不考虑当前路径，所以不保存
        //保存现在得上下文图形状态。不管后续对context上绘制什么都不会影响真正得屏幕。
        CGContextSaveGState(context);
        //x，y轴方向移动
        CGContextTranslateCTM(context , 0 ,self.bounds.size.height);
        //缩放x，y轴方向缩放，－1.0为反向1.0倍,坐标系转换,沿x轴翻转180度
        CGContextScaleCTM(context, 1.0 ,-1.0);
        CTFrameDraw(frame,context);
        
        CGContextRestoreGState(context);
        CGPathRelease(path);
        CFRelease(framesetter);
        CFRelease(frame);
    }
    
    for (int i = 0; i < self.times.count; i++) {
        NSNumber *startNumber = [self.times objectAtIndex:i++];
        NSTimeInterval start = [startNumber doubleValue];
        
        NSNumber *endNumber = [self.times objectAtIndex:i];
        NSTimeInterval end = [endNumber doubleValue];
        
        if (start > ONE_DAY) {
            start = (int)start % ONE_DAY;
        }
        if (end > ONE_DAY) {
            end = (int)end % ONE_DAY;
        }
        if (end<start) {//如果结束时间小于开始时间 ／／add by zjs
            end = start;//容错处理
            //处理开始时间2015-09-11 23:53:43，结束时间2015-09-12 00:03:43.
            if (start - end >= ONE_DAY - 11*60) {//默认视频最长是10分钟，处理兼容，设置最长时间设置为11分钟。
                end = ONE_DAY;
            }
        }
        float x1 = start / ONE_DAY * w - clipX;//x1，x2数据类型将int改为float，绘制宽度小于一个像素的视频数据。 change by zjs
        float x2 = end / ONE_DAY * w - clipX;
        
        bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(x1 + Margin_Left_Right,0,x2 - x1,self.frame.size.height)];
        [self.validBgColor setFill];
        [bezierPath fill];
        
        bezierPath = [UIBezierPath bezierPathWithRect:CGRectMake(x1 + Margin_Left_Right,y,x2 - x1,2)];
        [self.progressValidColor setFill];
        [bezierPath fill];
    }
    
    UIImage* im = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return im;
}




@end

