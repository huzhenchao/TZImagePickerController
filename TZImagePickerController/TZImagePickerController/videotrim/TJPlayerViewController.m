//
//  TJPlayerViewController.m
//  TJVideoEditer
//
//  Created by TanJian on 17/2/10.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import "TJPlayerViewController.h"
#import "TJMediaManager.h"
#import <AVFoundation/AVFoundation.h>
#import "TimeChooseView.h"
#import <Photos/Photos.h>
#import "TJPhotoManager.h"
#import "NSBundle+TZImagePicker.h"

//添加外部音频的路径宏（后期需要加入外部音频到视频中可以直接传入此音频url，当然名字自己写）
#define AUDIO_URL [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"新歌" ofType:@"mp3"]]


@interface TJPlayerViewController ()<UIGestureRecognizerDelegate>

@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property(nonatomic,strong) AVPlayerItem *playerItem;

@property (nonatomic,assign) CGFloat startTime;             //裁剪开始时间点
@property (nonatomic,assign) CGFloat endTime;               //裁剪结束时间点
@property (nonatomic,strong) NSTimer *timer;                //计时器控制预览视频长度
@property (nonatomic,assign) CGFloat playTime;

@property(nonatomic,strong) UIImage *image;
@property(nonatomic,strong) UIButton *cutBtn;
@property(nonatomic,strong) UIButton *backBtn;

@property (nonatomic,strong) PHFetchResult *collectonResuts;

@property(nonatomic,strong) TimeChooseView *chooseView;
/*!
 * 导航条状态
 */
@property(nonatomic,assign) BOOL isHidden;

@end

@implementation TJPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    //设置默认起始时间点
    _startTime = 0;
    _endTime = 15;
    //    [self preViewAction];
    _playTime = 0;
    _timer = [NSTimer timerWithTimeInterval:0.04 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    [self setVideoViewWithUrlPath:_videoUrl.path];
    [self setupUI];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
        [self TimeChooseView];
    });
}


-(void)setupUI{
    
    //demo中的按钮
    UIButton *cutBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.width-50, self.view.bounds.size.height -60,40, 40)];
    [cutBtn setTitle:@"完成" forState:UIControlStateNormal];
    [cutBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [cutBtn addTarget:self action:@selector(cutVideoAction) forControlEvents:UIControlEventTouchUpInside];
    _cutBtn = cutBtn;
    [self.view addSubview:cutBtn];
    
    UIButton *backBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, self.view.bounds.size.height -60, 40, 40)];
    [backBtn setTitle:@"取消" forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(cancelOrDoneCutAction) forControlEvents:UIControlEventTouchUpInside];
    _backBtn = backBtn;
    [self.view addSubview:backBtn];

}

-(void)TimeChooseView{
    //裁剪操作控制区
    self.chooseView = [[TimeChooseView alloc]initWithFrame:CGRectMake(40, self.view.bounds.size.height - 120,self.view.bounds.size.width-80,50)];
    _chooseView.videoURL = self.videoUrl;
    _chooseView.maxSelectArea = self.maxSelectArea;
    //超出部分不隐藏
    _chooseView.layer.masksToBounds = NO;
    
    __block typeof (self)weakself = self;
    _chooseView.getTimeRange = ^(CGFloat startTime,CGFloat endTime,CGFloat imageTime){

        weakself.startTime = startTime;
        weakself.endTime = endTime;
        
        [weakself jumpToTime:imageTime];
    };
    
    _chooseView.cutWhenDragEnd = ^{
        
        __strong typeof(weakself) strongSelf = weakself;
        [strongSelf preViewAction];
        
    };
    
    [_chooseView setupUI];
    [self.view addSubview:_chooseView];
}

-(void)setVideoViewWithUrlPath:(NSString *)url{
    
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:url]];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height-130);
    [self.view.layer addSublayer:self.playerLayer];
    

    
    [self.view bringSubviewToFront:_cutBtn];
    [self.view bringSubviewToFront:_backBtn];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
}


-(void)timerAction{
    
    _playTime += 0.04;
    if (_endTime-_startTime-_playTime<0.04) {
        [self preViewAction];
        _playTime = 0;
    }
}

-(void)preViewAction{
    
    [_player seekToTime:CMTimeMake(_startTime*30, 30) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [_player play];
    }];
    
}


-(void)cancelOrDoneCutAction{
    [self.player pause];
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:NO];
    }else{
        [self dismissViewControllerAnimated:NO completion:nil];

    }
    [self removeNotification];
    
}


-(void)cutVideoAction{
    
    __block UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height*0.5-10, self.view.bounds.size.width, 20)];
    label.text = [NSBundle tz_localizedStringForKey:@"Processing video"];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor whiteColor];
    [label sizeToFit];
    CGFloat width = label.frame.size.width*2;
    CGFloat height = label.frame.size.height*2;
    CGFloat lx = (self.view.bounds.size.width - width)/2;
    CGFloat ly = label.frame.origin.y;
    label.frame = CGRectMake(lx, ly, width, height);
    [self.view addSubview:label];
    
    [_player pause];
    if (_videoUrl  && self.startTime>=0 && self.endTime>self.startTime) {
        
        TimeRange timeRange = {_startTime,_endTime-_startTime};
        
        __weak typeof(self) weakself = self;
        [TJMediaManager addBackgroundMiusicWithVideoUrlStr:_videoUrl audioUrl:nil andCaptureVideoWithRange:timeRange completion:^{
            NSLog(@"视频裁剪完成");
            
            NSString* videoName = KcutVideoPath;
            NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
            
            [[TJPhotoManager sharedInstance] saveVideoWithPathString:exportPath Success:^(PHAsset *asset) {
                
                __strong typeof(self) strongself = weakself;
                if (strongself.cutDoneBlock) {
                    strongself.cutDoneBlock(asset);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [label removeFromSuperview];
                    [strongself cancelOrDoneCutAction];
                    
                });
                
            } error:^(NSString *error) {
                NSLog(@"错误%@",error);
            }];
        }];
    }
}


-(void)jumpToTime:(CGFloat )time{
    
    [_player pause];
    [_player seekToTime:CMTimeMake(time*30, 30) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
    }];
}

-(void)playbackFinished{
    
    NSLog(@"视频播放完成.");
    // 播放完成后重复播放
    // 跳到剪切开始处
    [_player seekToTime:CMTimeMake(_startTime*30, 30)];
    [_player play];
}


-(void)removeNotification{
    
    [_timer invalidate];
    _timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.player = nil;
    self.playerItem = nil;
    self.playerLayer = nil;
    [self.chooseView removeFromSuperview];
    self.chooseView = nil;
}

-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.isHidden = self.navigationController.navigationBarHidden;
    self.navigationController.navigationBarHidden = YES;
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = self.isHidden;
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

-(void)dealloc{
    
    NSLog(@"TJPlayerViewController --");
    
}
@end
