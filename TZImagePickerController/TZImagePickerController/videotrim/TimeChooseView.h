//
//  TimeChooseView.h
//  TJVideoEditer
//
//  Created by TanJian on 17/2/13.
//  Copyright © 2017年 Joshpell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeChooseView : UIView

@property (nonatomic,strong)NSURL *videoURL;
/*!
 * 最大时间区间，单位：秒，默认15秒
 */
@property(nonatomic,assign) NSInteger maxSelectArea;
//开始时间改变时的回调
@property (nonatomic,copy) void (^getTimeRange )(CGFloat startTime,CGFloat endTime,CGFloat imageTime);
//结束时间变化的回调
@property (nonatomic,copy) void (^cutWhenDragEnd)();

/**
 * 初始化渲染方法
 */
-(void)setupUI;
-(void)clearResource;
@end
