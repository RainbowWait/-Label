//
//  HYExpandableLabel.h
//  HYExpandableLabel
//
//  Created by zheng on 2019/7/4.
//  Copyright © 2019年 zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
	XYExpandableLabelActionClick,
	XYExpandableLabelActionDidCalculate
} XYExpandableLabelActionType;

@interface XYExpandableLabelContentView: UIView
@end



@interface XYExpandableLabel : UIView
//text
@property(nonatomic,copy)NSAttributedString *attributedText;
/**限制最多行数 默认为3 */
@property(nonatomic)NSUInteger maximumLines;

@property(nonatomic,copy)void(^action)(XYExpandableLabelActionType type, id info);
/** 行间距  默认为0 */
@property (nonatomic, assign) CGFloat lineSpace;
/** text的颜色  默认blackColor*/
@property (nonatomic, strong) UIColor *textColor;
/** 收起/展开颜色 默认blueColor*/
@property (nonatomic, strong) UIColor *expandColor;
/** 字体大小 默认14*/
@property (nonatomic, assign) CGFloat fontSize;

@end
