//
//  UserCell.m
//  WhosAtGlue
//
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

#import "UserCell.h"

#import "KCSUser+WhosAtGlue.h"

@implementation UserCell


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    NSSet* myInterests = [NSSet setWithArray:[KCSUser activeUser].learnInterests];
    if (myInterests.count == 0) {
        return;
    }
    
    
    NSMutableSet* combinedInterests = [self.interests mutableCopy];
    [combinedInterests intersectSet:myInterests];
    CGFloat overlap = combinedInterests.count / (float) myInterests.count;
    
    
    CGRect lFrame = self.textLabel.frame;
    CGFloat x = lFrame.origin.x;
    CGFloat mx = CGRectGetMaxX(rect) - 34;
    CGFloat w = (mx - x) * overlap;
    mx = x + w;
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(x, CGRectGetMaxY(rect))];
    [path addLineToPoint:CGPointMake(x, CGRectGetMaxY(rect) - 12)];
    [path addLineToPoint:CGPointMake(mx, CGRectGetMaxY(rect) - 4)];
    [path addLineToPoint:CGPointMake(mx, CGRectGetMaxY(rect))];
    [path closePath];

    CGContextRef myContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(myContext);
    CGGradientRef myGradient;
    CGColorSpaceRef myColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat c = 0.9 - 0.6 * overlap;
    CGFloat components[8] = { c, 1, c, 1.0,  // Start color
                              0.9, 0.9, 0.9, 1.0 }; // End color
    
    myColorspace = CGColorSpaceCreateDeviceRGB();//CGColorSpaceCreateWithName(kCGColorSpace);
    myGradient = CGGradientCreateWithColorComponents (myColorspace, components, locations, num_locations);
    
    CGContextAddPath(myContext, path.CGPath);
    CGContextClip(myContext);
    
    CGPoint myStartPoint, myEndPoint;
    myStartPoint.x = x;
    myStartPoint.y = 0.0;
    myEndPoint.x = mx;
    myEndPoint.y = 0;
    CGContextDrawLinearGradient (myContext, myGradient, myStartPoint, myEndPoint, 0);
    
    CFRelease(myColorspace);
    CFRelease(myGradient);
    CGContextRestoreGState(myContext);
}

@end
