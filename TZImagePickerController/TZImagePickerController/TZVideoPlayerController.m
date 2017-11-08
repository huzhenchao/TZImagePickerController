//
//  TZVideoPlayerController.m
//  TZImagePickerController
//
//  Created by 谭真 on 16/1/5.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "TZVideoPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIView+Layout.h"
#import "TZImageManager.h"
#import "TZAssetModel.h"
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"
#import "TJPlayerViewController.h"

@interface TZVideoPlayerController () {
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
    UIButton *_playButton;
    UIImage *_cover;
    
    UIView *_toolBar;
    UILabel *_msglb;
    UIButton *_doneButton;
    UIProgressView *_progress;
    
    UIStatusBarStyle _originStatusBarStyle;
}
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation TZVideoPlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        self.navigationItem.title = tzImagePickerVc.previewBtnTitleStr;
    }
    [self configMoviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = iOS7Later ? UIStatusBarStyleLightContent : UIStatusBarStyleBlackOpaque;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = _originStatusBarStyle;
}

- (void)configMoviePlayer {
    [[TZImageManager manager] getPhotoWithAsset:_model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        _cover = photo;
    }];
    [[TZImageManager manager] getVideoWithAsset:_model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _player = [AVPlayer playerWithPlayerItem:playerItem];
            _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
            _playerLayer.frame = self.view.bounds;
            [self.view.layer addSublayer:_playerLayer];
            [self addProgressObserver];
            [self configPlayButton];
            [self configBottomToolBar];
            [self settingMsgandBtn];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
        });
    }];
}

/// Show progress，do it next time / 给播放器添加进度更新,下次加上
- (void)addProgressObserver{
    AVPlayerItem *playerItem = _player.currentItem;
    UIProgressView *progress = _progress;
    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([playerItem duration]);
        if (current) {
            [progress setProgress:(current/total) animated:YES];
        }
    }];
}

- (void)configPlayButton {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setImage:[UIImage imageNamedFromMyBundle:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamedFromMyBundle:@"MMVideoPreviewPlayHL"] forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playButton];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    _msglb = [[UILabel alloc]init];
    _msglb.font = [UIFont systemFontOfSize:14];
    _msglb.numberOfLines = 0;
    _msglb.textColor = [UIColor whiteColor];
    [_toolBar addSubview:_msglb];
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.tag = 0;
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc) {
        [_doneButton setTitle:tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
        [_doneButton setTitleColor:tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    } else {
        [_doneButton setTitle:[NSBundle tz_localizedStringForKey:@"Done"] forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0] forState:UIControlStateNormal];
    }
    [_toolBar addSubview:_doneButton];
    [self.view addSubview:_toolBar];
}

- (void)settingMsgandBtn {
    double _duration = 0.0;
    if ([self.model.asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)self.model.asset;
        _duration = phAsset.duration;
    } else {
        _duration = [[self.model.asset valueForProperty:ALAssetPropertyDuration] doubleValue];
    }
    //大于最大可选时长时
    if (_duration > self.maxVideoLength && self.maxVideoLength != 0) {
        //提示不能选择此视频
        _msglb.text = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"You can't choose videos more than %d minutes"], self.maxVideoLength/60];
        _doneButton.hidden = YES;
    }
    //介于中间进行编辑
    else if(self.outVideoLength < _duration && _duration < self.maxVideoLength){
        _msglb.text = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Only %d seconds of the video, you need to edit"], self.outVideoLength];
        _doneButton.tag = 1;
        [_doneButton setTitle:[NSBundle tz_localizedStringForKey:@"Edit"] forState:UIControlStateNormal];
    }
}
#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    _playerLayer.frame = self.view.bounds;
    _playButton.frame = CGRectMake(0, 64, self.view.tz_width, self.view.tz_height - 64 - 44);
    _msglb.frame = CGRectMake(6, 0, self.view.tz_width - 44 - 12 - 6, 44);
    _doneButton.frame = CGRectMake(self.view.tz_width - 44 - 12, 0, 44, 44);
    _toolBar.frame = CGRectMake(0, self.view.tz_height - 44, self.view.tz_width, 44);
}

#pragma mark - Click Event

- (void)playButtonClick {
    CMTime currentTime = _player.currentItem.currentTime;
    CMTime durationTime = _player.currentItem.duration;
    if (_player.rate == 0.0f) {
        if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        [_player play];
        [self.navigationController setNavigationBarHidden:YES];
        _toolBar.hidden = YES;
        [_playButton setImage:nil forState:UIControlStateNormal];
        if (!TZ_isGlobalHideStatusBar) {
            if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = YES;
        }
    } else {
        [self pausePlayerAndShowNaviBar];
    }
}

-(void)callBack{
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if (self.navigationController) {
        if (imagePickerVc.autoDismiss) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [self callDelegateMethod];
            }];
        } else {
            [self callDelegateMethod];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethod];
        }];
    }
}

- (void)doneButtonClick:(UIButton *)sender {
    //正常情况
    if (sender.tag == 0) {
        [self callBack];
    }
    //需要剪切视频
    else{
        [[TZImageManager manager] getVideoUrlWithAsset:_model.asset completion:^(NSURL *url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                TJPlayerViewController *pvc = [[TJPlayerViewController alloc] init];
                pvc.videoUrl = url;
                pvc.maxSelectArea = self.outVideoLength;
                pvc.cutDoneBlock = ^(PHAsset *asset) {
                    _model.asset = asset;
                    [self callBack];
                };
                [self.navigationController pushViewController:pvc animated:YES];
            });
        }];
    }
}

- (void)callDelegateMethod {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingVideo:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate imagePickerController:imagePickerVc didFinishPickingVideo:_cover sourceAssets:_model.asset];
    }
    if (imagePickerVc.didFinishPickingVideoHandle) {
        imagePickerVc.didFinishPickingVideoHandle(_cover,_model.asset);
    }
}

#pragma mark - Notification Method

- (void)pausePlayerAndShowNaviBar {
    [_player pause];
    _toolBar.hidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    [_playButton setImage:[UIImage imageNamedFromMyBundle:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
    
    if (!TZ_isGlobalHideStatusBar) {
        if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = NO;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma clang diagnostic pop

@end
