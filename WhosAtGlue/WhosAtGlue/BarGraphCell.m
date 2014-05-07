//
//  BarGraphCell.m
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

#import "BarGraphCell.h"
#import "BarGraphView.h"

@interface BarGraphCell ()
@property (nonatomic, strong) UILabel *label;
@end


@implementation BarGraphCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 50)];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.text = @"B1";
        self.label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:self.label];
        
        self.barGraph = [[BarGraphView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        [self.contentView addSubview:self.barGraph];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect rect = self.contentView.bounds;
    self.label.frame = CGRectMake(0., 0, 29., rect.size.height);
    self.barGraph.frame = CGRectMake(29., 0., rect.size.width - 29. - 2., rect.size.height);
}

- (void)setTitle:(NSString *)title
{
    self.label.textColor = self.tintColor;
    self.label.text = title;
}

@end
