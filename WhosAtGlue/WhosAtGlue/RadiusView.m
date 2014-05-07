//
//  RaidusView.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/21/14.
//  Copyright 2014 Kinvey, Inc
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RadiusView.h"

@interface RadiusView () 
@property (nonatomic, strong) CAShapeLayer* antLayer;
@property (nonatomic, strong) UIActivityIndicatorView* spinner;
@property (nonatomic, strong) UILabel* loadingLabel;
@end


@implementation RadiusView

- (void) commonInit
{
    // Initialization code
    self.backgroundColor = [UIColor clearColor];
    self.maxDistance = 10;
    self.distance = self.maxDistance;
    self.disabledColor = [UIColor lightGrayColor];
    
    self.textColor = [UIColor reddishColor];
    self.circleColor = [UIColor lightTextColor];
    
    _antLayer = [[CAShapeLayer alloc] init];
    _antLayer.strokeColor = self.circleColor.CGColor;
    _antLayer.lineWidth = 1;
    _antLayer.backgroundColor = [UIColor clearColor].CGColor;
    _antLayer.opaque = NO;
    _antLayer.fillColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:_antLayer];
    
    if (self.animated) {
        [self spinAnts];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (CGRect) outsideRect:(CGFloat) dim
{
    CGRect beaconRect = CGRectMake(0, 0, dim, dim);
    
    CGFloat outsideDiameter = dim * 0.8;
    CGFloat outsidePadding = (dim - outsideDiameter) / 2.;
    CGRect outsideRect = CGRectInset(beaconRect, outsidePadding, outsidePadding);
    outsideRect = CGRectIntegral(outsideRect);

    return outsideRect;
}

- (void) drawOuter:(CGFloat)dim
{
    if (self.count == 0) {
        _antLayer.path = nil;
        return;
    }
    
    CGRect outsideRect = [self outsideRect:dim];
    
    UIBezierPath* outsideCircle = [UIBezierPath bezierPathWithOvalInRect:outsideRect];
    [self.circleColor setStroke];
    
    CGFloat outsideDiameter = dim * 0.8;
    CGFloat circumference = outsideDiameter * M_PI;
    CGFloat dashWidth = 2.;
    CGFloat minDashSeperation = 2.;
    NSUInteger maxAnts = circumference / (dashWidth + minDashSeperation);
    NSUInteger nAnts = MIN(maxAnts, self.count);
    
    while (maxAnts >= 2 * self.count) {
        dashWidth = 2. * dashWidth;
        minDashSeperation = 2. * minDashSeperation;
        maxAnts = circumference / (dashWidth + minDashSeperation);
        nAnts = MIN(maxAnts, self.count);
    }
    
    CGFloat dashSeperation = (circumference - nAnts * dashWidth) / (float) nAnts;
    
    NSMutableArray* ants = [NSMutableArray arrayWithCapacity:nAnts*2];
    for (int i = 0; i < nAnts; i++) {
        [ants addObject:@(dashWidth)];
        [ants addObject:@(dashSeperation)];
    }
    
    _antLayer.path = outsideCircle.CGPath;
    _antLayer.lineDashPattern = ants;
}

- (void) drawInner:(CGFloat)dim
{
    CGFloat distance = self.distance >= 0 ? self.distance : self.maxDistance;
    
    CGFloat percentage = MAX(self.maxDistance - distance, 0) / self.maxDistance;
    
    CGRect beaconRect = CGRectMake(0, 0, dim, dim);
    CGFloat insideDiameter = dim * 0.58 * percentage;
    CGFloat insidePadding = (dim - insideDiameter) / 2.;
    CGRect insideRect = CGRectIntegral(CGRectInset(beaconRect, insidePadding, insidePadding));
    insideRect = CGRectIntegral(insideRect);

    UIBezierPath* insideCircle = [UIBezierPath bezierPathWithOvalInRect:insideRect];
    [self.circleColor setFill];
    [insideCircle fill];
}

- (void) drawDisabled:(CGFloat)dim
{
    CGFloat percentage = 1;
    CGRect beaconRect = CGRectMake(0, 0, dim, dim);
    CGFloat insideDiameter = dim * 0.58 * percentage;
    CGFloat insidePadding = (dim - insideDiameter) / 2.;
    CGRect insideRect = CGRectIntegral(CGRectInset(beaconRect, insidePadding, insidePadding));
    insideRect = CGRectIntegral(insideRect);
    
    UIBezierPath* insideCircle = [UIBezierPath bezierPathWithOvalInRect:insideRect];
    [self.disabledColor setStroke];
    [insideCircle stroke];
    
    
    CGRect outsideRect = [self outsideRect:dim];
    
    UIBezierPath* outsideCircle = [UIBezierPath bezierPathWithOvalInRect:outsideRect];
    [outsideCircle stroke];
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGFloat dim = MIN(rect.size.height, rect.size.width);
    CGRect beaconRect = CGRectMake(0, 0, dim, dim);
    
    if (self.disabled) {
        [self drawDisabled:dim];
    } else {
        [self drawInner:dim];
        [self drawOuter:dim];
    }
    
    NSMutableParagraphStyle* paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paraStyle setAlignment:NSTextAlignmentCenter];
    
    CGFloat fontHeight = [UIFont systemFontOfSize:[UIFont systemFontSize]].pointSize;
    CGRect textRect = beaconRect;
    textRect.origin.y = (beaconRect.size.height - fontHeight) / 2.0;
    [self.title drawInRect:textRect withAttributes:@{NSForegroundColorAttributeName : self.textColor, NSParagraphStyleAttributeName : paraStyle}];
}

- (void)setCount:(NSUInteger)count
{
    _count = count;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateView];
    });
}

- (void)setDistance:(float)distance
{
    if (distance >= 0) {
        _distance = distance;
        [self updateView];
    }
}

- (void)setTitle:(NSString *)title
{
    if ([title length] == 0) {
        title = @"⚠︎";
    }
    _title = title;
    [self updateView];
}

- (void)setDisabled:(BOOL)disabled
{
    if (disabled != _disabled) {
        _disabled = disabled;
        _count = 0;
        [self updateView];
    }
}

- (void)setAnimated:(BOOL)animated
{
    if (animated != _animated) {
        _animated = animated;
        [self spinAnts];
    }
}

- (void)layoutSubviews
{
    CGRect rect = self.bounds;
    CGFloat dim = MIN(rect.size.height, rect.size.width);
    CGRect beaconRect = CGRectMake(0, 0, dim, dim);
    self.antLayer.frame = beaconRect;
    [self updateView];
}

- (void) updateView
{
    [self setNeedsDisplay];
}

#pragma mark - Ants

- (void)spinAnts
{
    [self.antLayer removeAllAnimations];
    if (self.animated) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.toValue = @(M_2_PI);
        animation.duration = 4;
        animation.cumulative = YES;
        animation.repeatCount = HUGE_VALF;
        
        [self.antLayer addAnimation:animation forKey:@"opacity"];
        self.antLayer.opacity = 0.99;
    } else {
        [self.antLayer removeAllAnimations];
    }
}

#pragma mark - Loading

- (void) setLoading:(BOOL)loading
{
    _loading = loading;
    if (loading) {
        if (!self.spinner) {
            self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            self.spinner.hidesWhenStopped = YES;
            CGFloat dim = MIN(self.bounds.size.height, self.bounds.size.width);
            [self addSubview:self.spinner];
            self.spinner.center = CGPointMake(dim/2, dim/2);
            
            CGRect f = CGRectMake(CGRectGetMaxX(self.spinner.frame) + 18, 8, 200, 40);
            self.loadingLabel = [[UILabel alloc] initWithFrame:f];
            self.loadingLabel.text = @"Locating...";
            self.loadingLabel.textColor = [UIColor foregroundColor];
            self.loadingLabel.backgroundColor = [UIColor clearColor];
            [self addSubview:self.loadingLabel];
        }
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
        [self.loadingLabel removeFromSuperview];
    }
}

//try bins, try pulses
@end
