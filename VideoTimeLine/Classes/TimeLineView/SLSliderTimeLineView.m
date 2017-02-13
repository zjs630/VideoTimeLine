//
//  SLSliderTimeLineView.m
//  LineView
//
//  Created by ZhangJingshun on 15/5/28.
//  Copyright (c) 2015年 SengLed. All rights reserved.
//

#import "SLSliderTimeLineView.h"

#define MaxLineWidth 10
#define LineWidth 3
#ifndef SL_HEX_COLOR
#define SL_HEX_COLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 green:((c>>8)&0xFF)/255.0 blue:((c)&0xFF)/255.0 alpha:((c>>24)&0xFF)/255.0]
#endif


@implementation SLSliderTimeLineView


- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 1;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGFloat w = rect.size.width;//w 需要大于等于maxLineWidth
    CGFloat h = rect.size.height;
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat onePointX = (w-MaxLineWidth)/2;
    CGFloat twoPointX = onePointX + MaxLineWidth/2; CGFloat twoPointY = MaxLineWidth-3;
    CGFloat threePointX = onePointX+MaxLineWidth;

    UIColor *redColor = SL_HEX_COLOR(0xfffd6000);
    [redColor setFill];//填充
    
    //画最上面的三角
    CGContextMoveToPoint(context, onePointX,0);
    CGContextAddLineToPoint(context, twoPointX,twoPointY);
    CGContextAddLineToPoint(context, threePointX,0);
    CGContextFillPath(context);
    
    //画矩形
    CGContextFillRect(context, CGRectMake((w - LineWidth)/2, 5, LineWidth, h-5*2));
    CGContextStrokePath(context);
    
    //画最下面的三角形
    CGContextMoveToPoint(context, onePointX,h);
    CGContextAddLineToPoint(context, twoPointX,h-twoPointY);
    CGContextAddLineToPoint(context, threePointX,h);
    CGContextFillPath(context);

}

 
@end
