//
//  BarGraphView.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/10/14.
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

#import "BarGraphView.h"

#define kMaxCount 100

@interface BarGraphView ()
@end

@implementation BarGraphView

/*
 NSDictionary* makeTime(NSDate* d)
 {
 return @{@"time":d,@"count":@(arc4random() % 100)};
 }
- (void) mockTime
{
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* c  = [gregorian components:(NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:[NSDate date]];
    
    
    NSMutableArray* times = [NSMutableArray array];
    c.hour = 8; c.minute = 0;
    NSDate* time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 8; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 9; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 9; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 10; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 10; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 11; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 11; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 12; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 12; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 13; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 13; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 14; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 14; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 15; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 15; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 16; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 16; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 17; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 17; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 18; c.minute = 0;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    c.hour = 18; c.minute = 30;
    time = [gregorian dateFromComponents:c];
    [times addObject:makeTime(time)];
    
    self.data = times;
}
*/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [self.tintColor setFill];
    
    __block CGFloat x = 6.;
    CGFloat y = 2.;
    CGFloat rh = CGRectGetHeight(rect) - y;
    CGFloat rw = CGRectGetWidth(rect) - x;
    CGFloat w = 2.;
    CGFloat sx = MAX((rw - w * self.data.count) / self.data.count, 0);
    x = rw;
    
    [self.data enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat h = [obj floatValue] / self.maxValue * rh;
        UIBezierPath* p = [UIBezierPath bezierPathWithRect:CGRectMake(x, rh - h + y, w, h)];
        [p fill];
        x -= sx + w;
        if (x < w) {
            *stop = YES;
        }
    }];
//    assert(x >= 0);
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - 2., CGRectGetMaxY(rect))];
    [[UIColor helperFontColor] setStroke];
    path.lineWidth = 1.;
    [path stroke];
}

- (void)setMockData
{
    NSUInteger count = 24 * 2 * 3;
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [arr addObject:@(arc4random_uniform(kMaxCount))];
    }
    self.data = arr;
}

- (void)setData:(NSArray *)data
{
    _data = [data copy];
    [self setNeedsDisplay];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
}
@end
