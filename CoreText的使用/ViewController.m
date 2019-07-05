//
//  ViewController.m
//  CoreText的使用
//
//  Created by mac on 2019/7/4.
//  Copyright © 2019 mac. All rights reserved.
//

#import "ViewController.h"
#import "XYExpandableLabel.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet XYExpandableLabel *textLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labHeight;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSMutableAttributedString *attributeText = [[NSMutableAttributedString alloc]initWithString:@"房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了1福建安定路附近的拉风巨大浪费的就是发了多少解放路附近奥克兰市附近房间打扫了房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了1福建安定路附近的拉风巨大浪费的就是发了多少解放路附近奥克兰市附近房间打扫了房间打开房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了1福建安定路附近的拉风巨大浪费的就是发了多少解放路附近奥克兰市附近房间打扫了房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了房间打开了发动机奥拉夫接待来访放大镜了1福建安定路附近的拉风巨大浪费的就是发了多少解放路附近奥克兰市附近房间打扫了房间打开"];
    _textLab.fontSize = 12;
    _textLab.lineSpace = 5;
    _textLab.textColor = [UIColor greenColor];
    _textLab.expandColor = [UIColor orangeColor];
    _textLab.attributedText = attributeText;
    __block typeof(self)weakSelf = self;
    self.textLab.action = ^(XYExpandableLabelActionType type, id info) {
        NSLog(@"====%@",info);
        weakSelf.labHeight.constant = [info doubleValue];
    };
}


@end
