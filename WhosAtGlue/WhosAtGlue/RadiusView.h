//
//  RaidusView.h
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

#import <UIKit/UIKit.h>

@interface RadiusView : UIView
@property (nonatomic, copy) NSString* title;
@property (nonatomic, strong) UIColor* circleColor;
@property (nonatomic, strong) UIColor* disabledColor;
@property (nonatomic, strong) UIColor* textColor;
@property (nonatomic) NSUInteger count;
@property (nonatomic) float distance;
@property (nonatomic) float maxDistance;
@property (nonatomic) BOOL disabled;
@property (nonatomic) BOOL animated;

- (CGRect) outsideRect:(CGFloat) dim;

@property (nonatomic) BOOL loading;
@end
