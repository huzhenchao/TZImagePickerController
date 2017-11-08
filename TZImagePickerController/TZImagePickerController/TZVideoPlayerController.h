//
//  TZVideoPlayerController.h
//  TZImagePickerController
//
//  Created by 谭真 on 16/1/5.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TZAssetModel;
@interface TZVideoPlayerController : UIViewController

@property (nonatomic, strong) TZAssetModel *model;
/*!
 * 最长可选择视频时长,单位：秒
 */
@property(nonatomic,assign) NSInteger maxVideoLength;
/*!
 * 输出最大时长,超过后自定义截取,单位：秒
 */
@property(nonatomic,assign) NSInteger outVideoLength;
@end
