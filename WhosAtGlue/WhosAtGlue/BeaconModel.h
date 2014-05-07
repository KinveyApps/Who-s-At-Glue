//
//  BeaconModel.h
//  WhosAtGlue
//
//  Created by Michael Katz on 3/10/14.
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

@import Foundation;

#import "NSDictionary+WhosAtGlue.h"
#import "KCSUser+Beacons.h"
#import "CLBeacon+WhosAtGlue.h"
#import "KCSIBeacon.h"

KCS_CONSTANT UserUpdated;

KCS_CONSTANT EventNewClosestBeacon;
KCS_CONSTANT EventUpdatedUserCount;
KCS_CONSTANT EventRangedClosestBeacon;
KCS_CONSTANT EventRangedClosestAfterReasonableTime;
KCS_CONSTANT EventErrorStarting;

@class BeaconModel;
typedef void(^ModelCallback)(BeaconModel* model);
typedef void(^ModelErrorCallback)(BeaconModel* model, NSError* error);


@interface BeaconModel : NSObject
@property (nonatomic) BOOL useMock;
@property (nonatomic) NSUInteger activeRecency; //mins
@property (nonatomic, strong) KCSBeaconInfo* activeBeacon;

+ (instancetype) model;

- (NSMutableDictionary*) beaconForId:(NSString*)beaconId;
- (void) usersAtBeacon:(NSString*)beaconId completion:(void(^)(NSArray* users, NSError* error))completion;
- (void) allUsers:(void(^)(NSArray* users, NSError* error))completion;
- (void) nearbyUsers:(void(^)(NSArray* users, NSError* error))completion;

- (void)startMonitoringAtEvent:(NSString *)eventId callback:(void(^)(BOOL started))callback;

- (void) registerForEvent:(NSString*)eventId callback:(id)callback;


- (void) setActiveUserDirty;
@end
