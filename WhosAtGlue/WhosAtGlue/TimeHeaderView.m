//
//  TimeHeaderView.m
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

#import "TimeHeaderView.h"

#define kStartX 30.

@interface TimeHeaderView ()
@property (nonatomic, strong) NSMutableArray* labels;
@end

@implementation TimeHeaderView

- (void) addLabel:(NSString*)text
{
    static CGFloat tx;
    CGFloat x = tx++*50;
    UILabel* l = [[UILabel alloc] initWithFrame:CGRectMake(kStartX+x, 4, 60, 40)];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor foregroundColor];
    l.text = text;
    l.transform = CGAffineTransformMakeRotation(-M_PI_4);
    l.adjustsFontSizeToFitWidth = YES;
    l.numberOfLines = 0;
    l.font = [UIFont systemFontOfSize:10.];
    [self addSubview:l];
    [self.labels addObject:l];

}

- (id)init
{
    self = [super init];
    if (self) {
        self.labels = [NSMutableArray array];
        [self addLabel:@"8am"];
        [self addLabel:@"10am"];
        [self addLabel:@"12pm"];
        [self addLabel:@"2pm"];
        [self addLabel:@"4pm"];
        [self addLabel:@"6pm"];
        self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(rect)+kStartX, CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect) - 2., CGRectGetMaxY(rect))];
    [[UIColor foregroundColor] setStroke];
    path.lineWidth = 1.;
    [path stroke];
}


- (void)setTimes:(NSArray *)times
{
    NSDateFormatter* f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"h:mma";
    NSDateFormatter* g = [[NSDateFormatter alloc] init];
    g.dateFormat = @"M-dd";
    
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSUInteger skip = times.count / 6;
    NSUInteger lastDay = -1;
    for (int i = 0; i < 6; i++) {
        NSNumber* n = times[i*skip];
        NSDate* d = [NSDate dateWithTimeIntervalSince1970:[n doubleValue]/(1.0*MSEC_PER_SEC)];
        NSDateComponents* c = [gregorian components:NSCalendarUnitDay | NSCalendarUnitMonth fromDate:d];

        UILabel* l = self.labels[i];
        
        if (c.day != lastDay) {
            //have a new day
            lastDay = c.day;
            NSString* moText = [g stringFromDate:d];
            dispatch_async(dispatch_get_main_queue(), ^{
                CGRect lf = l.frame;
                CGRect fr = CGRectMake(lf.origin.x, 0, 100, 16);
                UILabel* m = [[UILabel alloc] initWithFrame:fr];
                m.textColor = [UIColor foregroundColor];
                m.text = moText;
                m.font = [UIFont systemFontOfSize:10.];
            
                [self addSubview:m];
            });
        }
        
        NSString* timeText = [[f stringFromDate:d] lowercaseString];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            l.text = timeText;
        });

    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect r = self.bounds;
    CGFloat w = (r.size.width - kStartX)/ 6.;
    for (int i = 0; i < 6; i++) {
        UILabel* l = self.labels[i];
        l.transform = CGAffineTransformIdentity;
        CGRect f = l.frame;
        f.origin.x = i * w + kStartX;
        l.frame = f;
        l.transform = CGAffineTransformMakeRotation(-M_PI_4);
    }
}

@end
