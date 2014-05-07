//
//  DistanceViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/1/14.
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

#import "DistanceViewController.h"

#import "KCSUser+Beacons.h"

#import "RadiusView.h"
#import "BeaconModel.h"

@interface DistanceViewController ()
@property (nonatomic, strong) NSTimer* updateTimer;
@property (nonatomic, strong) NSDate* expiration;
@end

@implementation DistanceViewController

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lurkButton.showsBorder = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged) name:KCSActiveUserChangedNotification object:nil];

    [[BeaconModel model] registerForEvent:EventNewClosestBeacon callback:^(BeaconModel *model) {
        if (self.disabled) {
            self.disabled = NO;
        }
        NSString* beacon = model.activeBeacon.plistObject.beaconId;
        if (beacon) {
            NSDictionary* beaconInfo = [model beaconForId:beacon];
            self.radiusView.title = beaconInfo[@"name"];
            self.radiusView.count = 0;
        }
    }];
    [[BeaconModel model] registerForEvent:EventRangedClosestBeacon callback:^(BeaconModel *model, NSError* error) {
        if (!error) {
            self.radiusView.disabled = NO;
            self.radiusView.animated = YES;
            self.radiusView.distance = model.activeBeacon.accuracy;
        } else {
            self.radiusView.disabled = YES;
            self.radiusView.animated = NO;
            self.radiusView.count = NO;
        }
    }];
    [[BeaconModel model] registerForEvent:EventRangedClosestAfterReasonableTime callback:^(BeaconModel *model) {
        [model usersAtBeacon:model.activeBeacon.plistObject.beaconId completion:^(NSArray *users, NSError *error) {
            if (!error) {
                self.radiusView.count = users.count;
            }
        }];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.lurkButton.selected = [KCSUser activeUser].lurking;
}

- (IBAction)toggleLurk:(UIButton*)sender
{
    BOOL currentState = [KCSUser activeUser].lurking;
    BOOL newState = !currentState;
    [KCSUser activeUser].lurking = newState;
    
    if (newState) {
        NSTimeInterval fifteenMinutes = 15 * SEC_PER_MINUTE;
        self.expiration = [NSDate dateWithTimeIntervalSinceNow:fifteenMinutes];
        [self.updateTimer invalidate];
        self.updateTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateInterval:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.updateTimer forMode:NSRunLoopCommonModes];
      
        [sender setTitle:@"Hiding" forState:UIControlStateSelected];
    } else {
        [self.updateTimer invalidate];
    }
}

- (void)updateInterval:(NSTimer*)timer
{
    NSTimeInterval interval = [self.expiration timeIntervalSinceNow];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    [self.lurkButton setTitle:formattedDate forState:UIControlStateSelected];
    
    if (interval < 0) {
        [self.updateTimer invalidate];
        self.lurkButton.selected = NO;
    }
}

- (void) userChanged
{
    if (![KCSUser activeUser]) {
        [self.updateTimer invalidate];
    }
}


- (void)setDisabled:(BOOL)disabled
{
    _disabled = disabled;
    if (disabled) {
        self.radiusView.disabled = YES;
        self.radiusView.title = nil;
        self.radiusView.loading = NO;
        self.lurkButton.enabled = NO;
    } else {
        self.radiusView.disabled = NO;
        self.lurkButton.enabled = YES;
        if ([KCSUser activeUser].lurking) {
            self.lurkButton.selected = YES;
            [self toggleLurk:self.lurkButton];
        }
    }
}

@end
