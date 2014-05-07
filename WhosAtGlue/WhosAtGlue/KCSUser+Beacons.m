//
//  KCSUser+Beacons.m
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

#import "KCSUser+Beacons.h"
#import "BeaconModel.h"
#import "NSDictionary+WhosAtGlue.h"

#define kBeaconKey @"nearestBeacon"
#define kLurking @"lurking"

static BOOL _user_dirty; //static okay for a quick fix b/c there is only one active user, and the side effects for getting this wrong are minor (an extra, unnecessary save)

@implementation KCSUser (Beacons)
@dynamic lurking;
@dynamic dirty;

- (void)setNearestBeaconInfo:(KCSBeaconInfo *)nearestBeaconInfo
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:[nearestBeaconInfo plistObject]];
    d[@"timestamp"] = [NSDate date];
    d[@"id"] = [d beaconId];
    
    [self setValue:d forAttribute:kBeaconKey];
}

- (KCSBeaconInfo *)nearestBeaconInfo
{
    return [self getValueForAttribute:kBeaconKey];
}

- (BOOL)lurking
{
    return [[self getValueForAttribute:kLurking] boolValue];
}

- (void)setLurking:(BOOL)lurking
{
    [self setValue:@(lurking) forAttribute:kLurking];
    self.dirty = YES;
}


- (void)setDirty:(BOOL)dirty
{
    _user_dirty = dirty;
}

- (BOOL)dirty
{
    return _user_dirty;
}

@end
