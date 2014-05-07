//
//  UIColor+WhosAtGlue.h
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

#import "UIColor+WhosAtGlue.h"
#import "UIColor+MKHelpers.h"

@implementation UIColor (WhosAtGlue)

+ (instancetype) backgroundColor
{
    return [UIColor whiteColor];//[UIColor colorWithHexString:@"f15a29"];
}

+ (instancetype)foregroundColor
{
    return [UIColor whiteColor];
}

+ (instancetype)lightTextColor
{
    return [UIColor colorWithHexString:@"fff9f3"];
}

+ (instancetype) helperFontColor
{
    return [UIColor colorWithHexString:@"ffcfae"];
}

+ (instancetype) graySubtitleColor
{
    return [UIColor colorWithHexString:@"7c7c7c"];
}

+ (instancetype) reddishColor
{
    return [UIColor colorWithHexString:@"8c2a10"];
}

+ (instancetype) orangishColor
{
    return [UIColor colorWithIntRed:240 green:90 blue:41];
}
@end
