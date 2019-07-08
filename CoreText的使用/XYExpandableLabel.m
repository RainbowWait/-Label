//
//  HYExpandableLabel.m
//  HYExpandableLabel
//
//  Created by zhuxuhong on 2019/7/7.
//  Copyright © 2019年 zheng. All rights reserved.
//

#import "XYExpandableLabel.h"
#import <CoreText/CoreText.h>
#pragma mark - HYExpandableLabelContentView
@interface XYExpandableLabelContentView()

@property(copy, nonatomic)NSAttributedString *attributedText;
/**限制最多行数 默认为3 */
@property(nonatomic)NSUInteger maximumLines;

@property(nonatomic,copy)void(^action)(XYExpandableLabelActionType type, id info);

@end

@implementation XYExpandableLabelContentView
- (void)dealloc
{
    NSLog(@"========================================1");
}
-(void)drawRect:(CGRect)rect{
	[super drawRect:rect];
	
	if (!_attributedText) {
		return;
	}
	[self drawText];
}

#pragma mark - Setters Method
-(void)setAttributedText:(NSAttributedString *)attributedText{
    _attributedText = attributedText;
	
	[self setNeedsDisplay];
}

-(void)drawText{
    //获取当前上下文
	CGContextRef context = UIGraphicsGetCurrentContext();
    
//设置字形变换矩阵为CGAffineTransformIdentity，也就是说每一个字形都不做图形变换
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    ///将当前context的坐标系进行flip
    CGContextScaleCTM(context, 1.0, -1.0);
	
	CTFramesetterRef setter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedText);
	
	CTFrameRef ctFrame = CTFramesetterCreateFrame(setter, CFRangeMake(0, _attributedText.length), CGPathCreateWithRect(self.bounds, nil), NULL);
	
	CTFrameDraw(ctFrame, context);
    CFRelease(ctFrame);
    CFRelease(setter);
}

@end


#pragma mark - HYExpandableLabel

typedef void(^XYAttributedTextDrawCompletion)(CGFloat height, NSAttributedString *drawAttributedText);

@interface XYExpandableLabel()

#pragma mark - Private Properties
@property(nonatomic,copy)NSAttributedString *clickAttributedText;
@property(nonatomic,copy)XYExpandableLabelContentView *contentView;
@property(nonatomic)BOOL isExpanded;
@property (nonatomic, assign) BOOL isNewLine;
@property(nonatomic)CGRect clickArea;

@end

@implementation XYExpandableLabel
{
	CGFloat _lineHeightErrorDimension; //误差值 默认为0.5
}

#pragma mark - Initial Method
- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    NSLog(@"========================================2");
}
-(instancetype)initWithFrame:(CGRect)frame{
	if (self = [super initWithFrame:frame]) 
	{
		[self initData];
		
		[self setupUI];
	}
	return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
	if (self = [super initWithCoder:aDecoder]) 
	{
		[self initData];
		
		[self setupUI];
	}
	return self;
}

-(void)setupUI{
	self.backgroundColor = [UIColor clearColor];
	[self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionGestureTapped:)]];
}

-(void)initData{
	_lineHeightErrorDimension = 0;
	self.maximumLines = 3;
    self.lineSpace = 0;
    self.textColor = [UIColor blackColor];
    self.expandColor = [UIColor blueColor];
    self.fontSize = 14;
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(actionNotificationReceived:) name:UIDeviceOrientationDidChangeNotification object:nil];
}


#pragma mark - Lifecycle Method
-(void)drawRect:(CGRect)rect{
	[super drawRect:rect];
	
	if (!self.attributedText) {
		return;
	}
	__weak typeof(self)weakSelf = self;
	[self drawTextWithCompletion:^(CGFloat height, NSAttributedString *drawAttributedText) {
		[weakSelf addSubview:weakSelf.contentView];
        weakSelf.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, height);
        weakSelf.contentView.backgroundColor = [UIColor clearColor];
		weakSelf.contentView.attributedText = drawAttributedText;
        weakSelf.action ? weakSelf.action(XYExpandableLabelActionDidCalculate, @(height)) : nil;
	}];
}


#pragma mark - Setters Method
-(void)setAttributedText:(NSAttributedString *)attributedText{
    NSMutableAttributedString *attri = (NSMutableAttributedString *)attributedText;
    [attri addAttribute:(id)kCTForegroundColorAttributeName value:self.textColor range:NSMakeRange(0, attri.length)];
    CTFontRef font = CTFontCreateWithName(CFSTR(".SFUIText"), self.fontSize, NULL);
    [attri addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:NSMakeRange(0, attri.length)];
    [self addGlobalAttributeWithContent:attri font:[UIFont systemFontOfSize:self.fontSize]];
	_attributedText = attri;
	
	[self setNeedsDisplay];
}

-(void)setMaximumLines:(NSUInteger)maximumLines{
	_maximumLines = maximumLines;
	[self setNeedsDisplay];
}
- (void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
}
- (void)setLineSpace:(CGFloat)lineSpace {
    _lineSpace = lineSpace;
}

-(void)setIsExpanded:(BOOL)isExpanded{
	_isExpanded = isExpanded;
	[self setNeedsDisplay];
}

#pragma mark - Public Method


#pragma mark - Action Method
-(void)actionNotificationReceived: (NSNotification*)sender{
	if ([sender.name isEqualToString:UIDeviceOrientationDidChangeNotification]) {
		self.isExpanded = self.isExpanded;
	}
}

-(void)actionGestureTapped: (UITapGestureRecognizer*)sender{
	if (CGRectContainsPoint(_clickArea, [sender locationInView:self])) {
		self.isExpanded = !self.isExpanded;
		self.action ? self.action(XYExpandableLabelActionClick, @(self.contentView.frame.size.height)) : nil;
	}
}

#pragma mark - Private Method
-(void)drawTextWithCompletion: (XYAttributedTextDrawCompletion)completion{
	self.isExpanded
	? [self calculateFullTextWithCompletion:completion] 
	: [self calculatePartialTextWithCompletion:completion];
}
/** 全部显示 */
-(void)calculateFullTextWithCompletion: (XYAttributedTextDrawCompletion)completion {
	
	CGPathRef path = CGPathCreateWithRect(CGRectMake(0, 0, self.bounds.size.width, UIScreen.mainScreen.bounds.size.height), nil);
    //加了 "收起>"的Text
	NSMutableAttributedString *drawAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:_attributedText];
	[drawAttributedText appendAttributedString:self.clickAttributedText];
    //没加加了 "收起>"的Text
    NSMutableAttributedString *drawAttributedText1 = [[NSMutableAttributedString alloc] initWithAttributedString:_attributedText];
    NSInteger line1Count = [self numberOfLinesForAttributtedText:drawAttributedText1];
    CTFramesetterRef setter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)drawAttributedText);
    // CTFrameRef
	CTFrameRef ctFrame = CTFramesetterCreateFrame(setter, CFRangeMake(0, drawAttributedText.length), path, NULL);
    // CTLines
    NSArray *lines = (NSArray*)CTFrameGetLines(ctFrame);
    CGPoint origins[lines.count];
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), origins);
	CGFloat totalHeight = 0;
    if (lines.count > line1Count) {
        self.isNewLine = YES;
        drawAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:_attributedText];
        [drawAttributedText appendAttributedString:self.clickAttributedText];
      setter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)drawAttributedText);
        ctFrame = CTFramesetterCreateFrame(setter, CFRangeMake(0, drawAttributedText.length), path, NULL);
        
        // CTLines
        lines = (NSArray*)CTFrameGetLines(ctFrame);
        
    } else {
        self.isNewLine = NO;
    }
	
	for (int i=0; i<lines.count; i++) {
		CTLineRef line = (__bridge CTLineRef)lines[i];
		totalHeight += [self heightForCTLine:line];
		
		if (i == lines.count - 1) {
			CTLineRef moreLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)self.clickAttributedText);
			
			NSArray *runs = (NSArray*)CTLineGetGlyphRuns(line);
			CGFloat w = 0;
			for (int i=0; i<runs.count; i++) {
				if (i == runs.count - 1) {
					break;
				}
				CTRunRef run = (__bridge CTRunRef)runs[i];
				w += CTRunGetTypographicBounds(run, CFRangeMake(0, 0), NULL, NULL, NULL);
			}
			
			CGSize moreSize = CTLineGetBoundsWithOptions(moreLine, 0).size;
			CGFloat h = moreSize.height ;
			self.clickArea = CGRectMake(w, totalHeight - h, moreSize.width, h);

            CFRelease(moreLine);
		}
       
	}
	
    CFRelease(ctFrame);
    CFRelease(path);
    CFRelease(setter);
    completion(totalHeight, drawAttributedText);
}
- (void)addGlobalAttributeWithContent:(NSMutableAttributedString *)aContent font:(UIFont *)aFont
{
    CGFloat lineLeading = self.lineSpace; // 行间距
    
    const CFIndex kNumberOfSettings = 2;
//    //设置段落格式
//    CTParagraphStyleSetting lineBreakStyle;
//    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
//    lineBreakStyle.spec = kCTParagraphStyleSpecifierLineBreakMode;
//    lineBreakStyle.valueSize = sizeof(CTLineBreakMode);
//    lineBreakStyle.value = &lineBreakMode;
    
    //设置行距
    CTParagraphStyleSetting lineSpaceStyle;
    CTParagraphStyleSpecifier spec;
    spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
    lineSpaceStyle.spec = spec;
    lineSpaceStyle.valueSize = sizeof(CGFloat);
    lineSpaceStyle.value = &lineLeading;
    
    // 结构体数组
    CTParagraphStyleSetting theSettings[kNumberOfSettings] = {
        lineSpaceStyle,
    };
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, kNumberOfSettings);
    
    // 将设置的行距应用于整段文字
    [aContent addAttribute:NSParagraphStyleAttributeName value:(__bridge id)(theParagraphRef) range:NSMakeRange(0, aContent.length)];
    
//    CFStringRef fontName = (__bridge CFStringRef)aFont.fontName;
//    CTFontRef fontRef = CTFontCreateWithName(fontName, aFont.pointSize, NULL);
//    // 将字体大小应用于整段文字
//    [aContent addAttribute:NSFontAttributeName value:(__bridge id)fontRef range:NSMakeRange(0, aContent.length)];
//
//    // 给整段文字添加默认颜色
//    [aContent addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, aContent.length)];
    // 内存管理
    CFRelease(theParagraphRef);
//    CFRelease(fontRef);
}

/** 显示最大行数 */
-(void)calculatePartialTextWithCompletion: (XYAttributedTextDrawCompletion)completion{	
	CGPathRef path = CGPathCreateWithRect(CGRectMake(0, 0, self.bounds.size.width, UIScreen.mainScreen.bounds.size.height), nil);
    NSMutableAttributedString *attributed = (NSMutableAttributedString *)_attributedText;
	// CTFrameRef
	CTFramesetterRef setter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributed);
	CTFrameRef ctFrame = CTFramesetterCreateFrame(setter, CFRangeMake(0, attributed.length), path, NULL);
	
	// CTLines
	NSArray *lines = (NSArray*)CTFrameGetLines(ctFrame);
	
	// CTLine Origins
	CGPoint origins[lines.count];
	CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), origins);
	CGFloat totalHeight = 0;
	
	NSMutableAttributedString *drawAttributedText = [NSMutableAttributedString new];
	
	for (int i=0; i<lines.count; i++) {
		if (lines.count > _maximumLines && i == _maximumLines) {
			break;
		}
        //获取行
		CTLineRef line = (__bridge CTLineRef)lines[i];
        //获取该行的在整个attributed的范围
		CFRange range = CTLineGetStringRange(line);
        //截取这一行的text
		NSAttributedString *subAttr = [attributed attributedSubstringFromRange:NSMakeRange(range.location, range.length)];
        //当是限制的最多行数时
		if (lines.count > _maximumLines && i == _maximumLines - 1) {
			NSMutableAttributedString *drawAttr = (NSMutableAttributedString*)subAttr;
			for (int j=0; j<drawAttr.length; j++) {
                //所限制的最后一行的内容 + "展开>" 处理刚刚只显示成一行内容 如果不只一行 一个一个字符的减掉到只有一行为止
				NSMutableAttributedString *lastLineAttr = [[NSMutableAttributedString alloc] initWithAttributedString:[drawAttr attributedSubstringFromRange:NSMakeRange(0, drawAttr.length-j)]];
				[lastLineAttr appendAttributedString:self.clickAttributedText];
                //内容是否是只有一行
				NSInteger number = [self numberOfLinesForAttributtedText:lastLineAttr];
				if (number == 1) {
					[drawAttributedText appendAttributedString:lastLineAttr];
					CTLineRef moreLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)self.clickAttributedText);
					CGSize moreSize = CTLineGetBoundsWithOptions(moreLine, 0).size;
					
					self.clickArea = CGRectMake(self.bounds.size.width-moreSize.width, totalHeight, moreSize.width, moreSize.height);
					
					totalHeight += [self heightForCTLine:line];
                    CFRelease(moreLine);
					break;
				}
			}
            CFRelease(line);
            
		} else {
			[drawAttributedText appendAttributedString:subAttr];
			
			totalHeight += [self heightForCTLine:line];
		}
	}
	completion(totalHeight, drawAttributedText);
//    CFRelease(ctFrame);
    CFRelease(setter);
    CFRelease(path);
}

-(CGFloat)heightForCTLine: (CTLineRef)line{
	CGFloat h = 0;
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    h = MAX(h, ascent + descent + leading);
	return h + _lineHeightErrorDimension + self.lineSpace;
}

/** 计算text的行数 */
-(NSInteger)numberOfLinesForAttributtedText: (NSAttributedString*)text {
	CGPathRef path = CGPathCreateWithRect(CGRectMake(0, 0, self.bounds.size.width, UIScreen.mainScreen.bounds.size.height), nil);
	CTFramesetterRef setter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
	CTFrameRef ctFrame = CTFramesetterCreateFrame(setter, CFRangeMake(0, text.length), path, nil);
	NSArray *lines = (NSArray*)CTFrameGetLines(ctFrame);
    CFRelease(ctFrame);
    CFRelease(setter);
    CFRelease(path);
	return lines.count;
}


#pragma mark - Getters Method
-(NSAttributedString *)clickAttributedText{
    if (_isExpanded) {
        if (_isNewLine) {
            return [[NSAttributedString alloc] initWithString:@"\n收起＞" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.fontSize], NSForegroundColorAttributeName: self.expandColor}];
        } else {
            return [[NSAttributedString alloc] initWithString:@" 收起＞" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.fontSize], NSForegroundColorAttributeName: self.expandColor}];
        }
        
    }
	
   NSMutableAttributedString *moreString = [[NSMutableAttributedString alloc] initWithString:@"..." attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.fontSize], NSForegroundColorAttributeName: self.textColor}];
    NSAttributedString  *foldString = [[NSAttributedString alloc] initWithString:@"展开＞" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:self.fontSize], NSForegroundColorAttributeName: self.expandColor}];
    [moreString appendAttributedString:foldString];
    return moreString;
}

-(XYExpandableLabelContentView *)contentView{
	if (!_contentView) {
		XYExpandableLabelContentView *v = [XYExpandableLabelContentView new];
		v.backgroundColor = [UIColor clearColor];
		
		_contentView = v;
	}
	return _contentView;
}
@end
