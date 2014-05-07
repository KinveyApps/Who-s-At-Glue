//
//  CircleImageView.m
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

#import "CircleImageView.h"

@interface BorderView : UIView

@end
@implementation BorderView

- (void)drawRect:(CGRect)rect
{
    [[UIColor graySubtitleColor] setStroke];
    [[UIBezierPath bezierPathWithOvalInRect:self.bounds] stroke];
}

@end

@implementation CircleImageView

- (void) kcsCommonInit
{
    CAShapeLayer* shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
    self.layer.mask = shapeLayer;
    self.layer.masksToBounds = YES;

//    CAShapeLayer* borderLayer = [[CAShapeLayer alloc] init];
//    borderLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds,4,4)].CGPath;
//
//    borderLayer.borderColor = [UIColor blackColor].CGColor;
//    borderLayer.borderWidth = 1.;
//    //    borderLayer.opacity = 1.;
//    borderLayer.backgroundColor = [UIColor redColor].CGColor;
//    [self.layer addSublayer:borderLayer];
//    borderLayer.zPosition = -1000;
//    
//    self.layer.borderColor = [UIColor greenColor].CGColor;
//    self.layer.borderWidth = 2.;
    
    UIView* borderView = [[BorderView alloc] initWithFrame:self.bounds];
    borderView.opaque = NO;
    borderView.backgroundColor = [UIColor clearColor];
    
//    CAShapeLayer* blayer = [[CAShapeLayer alloc] init];
//    blayer.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
////    self.layer.mask = shapeLayer;
////    self.layer.masksToBounds = YES;
//    [borderView.layer addSublayer:blayer];
//    blayer.backgroundColor = [UIColor redColor].CGColor;
//    blayer.borderColor = [UIColor yellowColor].CGColor;
//    blayer.borderWidth = 4.;

//    borderView.layer.borderColor = [UIColor greenColor].CGColor;
//    borderView.layer.borderWidth = 2.;
    [self addSubview:borderView];
    
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self kcsCommonInit];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        [self kcsCommonInit];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self) {
        [self kcsCommonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self kcsCommonInit];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self kcsCommonInit];
    }
    return self;
}

- (void) tapped:(UITapGestureRecognizer*)tap
{
    if (self.delegate) {
        [self.delegate circleImageViewTapped:self];
    }
}
@end
