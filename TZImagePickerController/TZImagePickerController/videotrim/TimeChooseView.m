//
//  TimeChooseView.m
//  TJVideoEditer
//
//  Created by TanJian on 17/2/13.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import "TimeChooseView.h"
#import <AVFoundation/AVFoundation.h>
#import "TJMediaManager.h"
#import "NSBundle+TZImagePicker.h"

#define KendTimeButtonWidth self.bounds.size.width*0.5/3


@interface WZScrollView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGRect *rect;


-(void)drawImage:(UIImage *)image inRect:(CGRect)rect;

@end

@implementation WZScrollView

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    [_image drawInRect:rect];
}

-(void)drawImage:(UIImage *)image inRect:(CGRect)rect{
    
    _image = image;
    _rect = &rect;
    
    [self setNeedsDisplayInRect:rect];
}

@end

typedef enum {
    
    imageTypeStart,
    imageTypeEnd,
    
}imageType;


@interface TimeChooseView ()<UIScrollViewDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;

@property (nonatomic,strong) UIImageView *startView;
@property (nonatomic,strong) UIImageView *endView;
@property (nonatomic,strong) UIView *topLine;
@property (nonatomic,strong) UIView *bottomLine;

@property (nonatomic,assign) CGFloat startTime;
@property (nonatomic,assign) CGFloat endTime;

@property (nonatomic,assign) CGFloat totalTime;

//正在操作开始或者结束指示器的类型
@property (nonatomic,assign) imageType chooseType;


@property(nonatomic,strong) TJMediaManager *mediaManger;

@end


@implementation TimeChooseView

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.maxSelectArea = 15;
    }
    return self;
}

-(void)setupUI{
    self.mediaManger = [[TJMediaManager alloc]init];
    
    _totalTime = [TJMediaManager getVideoTimeWithURL:self.videoURL];
    _startTime = 0;
    _endTime = _maxSelectArea;
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.bounds];
    _scrollView.delegate = self;
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.bounces = NO;
    _scrollView.layer.masksToBounds = NO;
    [self addSubview:_scrollView];
    
    //展示图片能看到的宽度
    //    UIImage *tempImage = [self.mediaManger getCoverImage:self.videoURL atTime:0 isKeyImage:NO];
    //    CGSize normarlSize = tempImage.size;
    CGFloat imageShowW = self.bounds.size.width*1.0f/_maxSelectArea;
    CGFloat height = self.bounds.size.height;//imageShowW * normarlSize.height / normarlSize.width;
    //    if (normarlSize.width/normarlSize.height > 1) {
    //        //横屏视频
    //        if (height<self.bounds.size.height) {
    //            height = self.bounds.size.height;
    //            imageShowW = height * normarlSize.width / normarlSize.height;
    //        }
    //    }

    CGSize imgsize = CGSizeMake(imageShowW*1.5, height*1.5);
    
    _scrollView.contentSize = CGSizeMake(_totalTime*imageShowW, self.bounds.size.height);
    
    WZScrollView *view = [[WZScrollView alloc]initWithFrame:CGRectMake(0,0,_totalTime*imageShowW, self.bounds.size.height)];
    [_scrollView addSubview:view];
    
  
    //缩略图
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.mediaManger getCoverImageArr:self.videoURL imgSize:imgsize callBackHandler:^(UIImage *image,NSInteger index) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [view drawImage:image inRect:CGRectMake(index*imageShowW, 0, imageShowW, height)];
            });
        }];
    });
    
    //添加裁剪范围框
    self.startView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, KendTimeButtonWidth, self.bounds.size.height)];
    NSString *cutvideoleft = [[NSBundle tz_imagePickerBundle] pathForResource:@"cutvideoleft" ofType:@"png"];
    _startView.image = [UIImage imageWithContentsOfFile:cutvideoleft];
    _startView.tag = 99;
    UIPanGestureRecognizer * recognizer1 = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    recognizer1.maximumNumberOfTouches = 1;
    recognizer1.minimumNumberOfTouches = 1;
    [_startView addGestureRecognizer:recognizer1];
    [self addSubview:_startView];
    self.startView.userInteractionEnabled = YES;
    
    CGFloat tPhotoWidth = _maxSelectArea * imageShowW;
    self.endView = [[UIImageView alloc]initWithFrame:CGRectMake(tPhotoWidth-KendTimeButtonWidth, 0, KendTimeButtonWidth, self.bounds.size.height)];
    NSString *cutvideoright = [[NSBundle tz_imagePickerBundle] pathForResource:@"cutvideoright" ofType:@"png"];
    _endView.image = [UIImage imageWithContentsOfFile:cutvideoright];
    _endView.tag = 100;
    UIPanGestureRecognizer * recognizer2 = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    recognizer2.maximumNumberOfTouches = 1;
    recognizer2.minimumNumberOfTouches = 1;
    [_endView addGestureRecognizer:recognizer2];
    [self addSubview:_endView];
    self.endView.userInteractionEnabled = YES;
    
    self.topLine = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 3)];
    _topLine.backgroundColor = [UIColor whiteColor];
    [self addSubview:_topLine];
    
    self.bottomLine = [[UIView alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-3,self.topLine.frame.size.width, 3)];
    _bottomLine.backgroundColor = [UIColor whiteColor];
    [self addSubview:_bottomLine];
    
}


-(void)panAction:(UIPanGestureRecognizer *)panGR{
    
    UIView *view = panGR.view;
    CGPoint P = [panGR translationInView:self.superview];
    CGPoint oldOrigin = view.frame.origin;
    
    switch (view.tag) {
        case 99:
        {
            _chooseType = imageTypeStart;
            if(oldOrigin.x+P.x <= CGRectGetMaxX(self.endView.frame)-self.bounds.size.width/3.0f && oldOrigin.x+P.x>=0){
                
                view.frame = CGRectMake(oldOrigin.x+P.x, 0,KendTimeButtonWidth, self.bounds.size.height);
            }
        }
            break;
        case 100:
        {
            _chooseType = imageTypeEnd;
            if (oldOrigin.x+P.x+KendTimeButtonWidth-self.startView.frame.origin.x>=self.bounds.size.width/3.0f && oldOrigin.x+P.x+KendTimeButtonWidth<=self.bounds.size.width) {
                
                view.frame = CGRectMake(oldOrigin.x+P.x, 0,KendTimeButtonWidth, self.bounds.size.height);
            }
        }
            
            break;
        default:
            break;
    }
    
    self.topLine.frame = CGRectMake(self.startView.frame.origin.x, 0, self.endView.frame.origin.x-self.startView.frame.origin.x + KendTimeButtonWidth, 3);
    self.bottomLine.frame = CGRectMake(self.topLine.frame.origin.x, self.bounds.size.height-3, self.topLine.frame.size.width, 3);
    
    if(panGR.state == UIGestureRecognizerStateChanged)
    {
        [panGR setTranslation:CGPointZero inView:self.superview];
        
    }
    //实时计算裁剪时间
    [self calculateForTimeNodes];
    
    if (panGR.state == UIGestureRecognizerStateEnded) {
        if (self.cutWhenDragEnd) {
            self.cutWhenDragEnd();
        }
    }
}


//计算开始结束时间点
-(void)calculateForTimeNodes{
    
    CGPoint offset = _scrollView.contentOffset;
    
    //可滚动范围分摊滚动范围代表的剩下时间
    _startTime = (offset.x+self.startView.frame.origin.x)*_maxSelectArea*1.0f/self.bounds.size.width;
    _endTime = (offset.x + self.endView.frame.origin.x + KendTimeButtonWidth) * _maxSelectArea * 1.0f/self.bounds.size.width;
    
    //预览时间点
    CGFloat imageTime = _startTime;
    if (_chooseType == imageTypeEnd) {
        imageTime = _endTime;
    }
    
    
    if (self.getTimeRange) {
        self.getTimeRange(_startTime,_endTime,imageTime);
    }
}

#pragma mark scrollview代理

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    _chooseType = imageTypeStart;
    [self calculateForTimeNodes];
    NSLog(@"%f",scrollView.contentOffset.x);
    
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{

    if (self.cutWhenDragEnd) {
        self.cutWhenDragEnd();
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    if (self.cutWhenDragEnd) {
        self.cutWhenDragEnd();
    }

}

-(void)clearResource {
    
    [self.mediaManger clearResource];
    
}

-(void)dealloc{
    
    NSLog(@"TimeChooseView ---");
}

@end
