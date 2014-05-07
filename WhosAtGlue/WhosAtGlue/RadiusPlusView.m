//
//  RadiusPlusView.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/9/14.
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

#import "RadiusPlusView.h"

#import "KCSUser+WhosAtGlue.h"
#import "KCSUser+Beacons.h"

#define METER_TO_FEET 3.28084
#define kMaxDistance 15. //meters


@interface RadiusPlusView ()
@property (nonatomic, strong) NSArray* users;
@property (nonatomic) float myDistance;
@property (nonatomic, strong) NSMutableDictionary* bins;
@end

@implementation RadiusPlusView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGFloat dim = MIN(rect.size.height, rect.size.width);

    CGRect outerRect = [self outsideRect:dim];
    
    CGFloat x = CGRectGetMidX(rect);
    CGFloat iy = CGRectGetMaxY(outerRect);
    CGFloat my = CGRectGetMaxY(rect) - 20;

    CGFloat markerHW = 8;
    
    UIBezierPath* path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(x, iy)];
    [path addLineToPoint:CGPointMake(x, my)];
    [path moveToPoint:CGPointMake(x - markerHW, my)];
    [path addLineToPoint:CGPointMake(x + markerHW, my)];
    
    CGFloat h = my - iy;
    NSUInteger nMarkers = 3;
    CGFloat markerY = h / nMarkers;

    [path moveToPoint:CGPointMake(x - markerHW, iy + markerY)];
    [path addLineToPoint:CGPointMake(x + markerHW, iy + markerY)];
    [path moveToPoint:CGPointMake(x - markerHW, iy + 2 * markerY)];
    [path addLineToPoint:CGPointMake(x + markerHW, iy + 2 * markerY)];
    
    path.lineWidth = 2;
    UIColor* color = self.disabled ? self.disabledColor : self.circleColor;
    [color setStroke];
    [color setFill];
    [path stroke];
    
    NSDictionary *attr = @{NSForegroundColorAttributeName : color};
    NSAttributedString* fiveft = [[NSAttributedString alloc] initWithString:@"5m" attributes:attr];
    NSAttributedString* tenft = [[NSAttributedString alloc] initWithString:@"10m" attributes:attr];
    NSAttributedString* fifteenft = [[NSAttributedString alloc] initWithString:@"15m" attributes:attr];
    
    CGFloat nudge = 8;
    CGFloat tx = -2;
    [fiveft drawAtPoint:CGPointMake(0, iy + markerY - nudge)];
    [tenft drawAtPoint:CGPointMake(tx, iy + 2* markerY - nudge)];
    [fifteenft drawAtPoint:CGPointMake(tx, my - nudge)];
    
    if (!self.disabled) {
        /// draw me
        if (self.myDistance > 0) {
            CGFloat distance = MIN((CGFloat)self.myDistance, kMaxDistance);
            CGFloat percentage = distance / kMaxDistance;
            CGFloat myY = percentage * h + iy;
            CGFloat myRadius = 5;
            CGRect myRect = CGRectMake(x - myRadius, myY - myRadius, 2 * myRadius, 2 * myRadius);
            UIBezierPath* me = [UIBezierPath bezierPathWithOvalInRect:myRect];
            [[UIColor helperFontColor] setStroke];
            [me stroke];
        }
        
        [self.bins enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            CGFloat distance = MIN([key floatValue], kMaxDistance);
            CGFloat percentage = distance / kMaxDistance;
            
            CGFloat myY = percentage * h + iy;
            CGFloat myRadius = MIN(16, MAX(3, [obj intValue]));
            CGRect myRect = CGRectMake(x - myRadius, myY - myRadius, 2 * myRadius, 2 * myRadius);
            UIBezierPath* users = [UIBezierPath bezierPathWithOvalInRect:myRect];
            [users fill];
            
        }];
    }
}


- (void)setUsers:(NSArray *)users
{
    _users = users;
    [self setCount:users.count];
    
    if (!self.bins) {
        self.bins = [NSMutableDictionary dictionary];
    }
    
    [self.bins removeAllObjects];
    for (NSDictionary* u in users) {
        if (![u isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary* info = u[@"nearestBeacon"];
        float a =  [info[@"accuracy"] floatValue];
        if (a > 0) {
            NSUInteger d = lroundf(MIN(a, kMaxDistance));
            NSNumber* n = self.bins[@(d)];
            if (!n) {
                self.bins[@(d)] = @1;
            } else {
                self.bins[@(d)] = @([n integerValue] + 1);
            }
        }
    }
    [self setNeedsDisplay];
}

- (void)setDistance:(float)distance
{
    [super setDistance:distance];
    self.myDistance = distance;
    [self setNeedsDisplay];
}

@end
