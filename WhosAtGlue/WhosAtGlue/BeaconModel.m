//
//  BeaconModel.m
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

#import "BeaconModel.h"
#import "KCSIBeacon.h"

#import <KinveyKit/KinveyKit.h>

#define kSaveInterval 20 //seconds
#define kDirtyUpdateInterval 60 //seconds

NSString* const UserUpdated = @"WhosAtGlueUserUpdated";
NSString* const EventNewClosestBeacon = @"EventNewClosestBeacon";
NSString* const EventUpdatedUserCount = @"EventUpdatedUserCount";
NSString* const EventRangedClosestBeacon = @"EventRangedClosestBeacon";
NSString* const EventRangedClosestAfterReasonableTime = @"EventRangedClosestAfterReasonableTime";
NSString* const EventErrorStarting = @"EventErrorStarting";

@interface BeaconModel () <KCSBeaconManagerDelegate>
@property (nonatomic, strong) NSArray* beacons;
@property (nonatomic, strong) KCSAppdataStore* userStore;
@property (nonatomic, strong) KCSCachedStore* beaconStore;
@property (nonatomic, strong) KCSBeaconManager* beaconManager;
@property (nonatomic, strong) NSMutableDictionary* delegates;
@property (nonatomic, strong) NSDate* lastRangeTime;
@property (nonatomic) BOOL atConference;
@end

@implementation BeaconModel

+ (instancetype)model
{
    static BeaconModel* rm;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rm = [[self alloc] init];
    });
    return rm;
}

- (id)init
{
    self = [super init];
    if (self) {
        _activeRecency = 15;
        _userStore = [KCSCachedStore storeWithCollection:[KCSCollection userCollection] options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst)}];
        _beaconManager = [[KCSBeaconManager alloc] init];
        _beaconManager.delegate = self;
        
        _beaconStore = [KCSCachedStore storeWithCollection:[KCSCollection collectionFromString:@"roomBeacons" ofClass:[NSMutableDictionary class]] options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst)}];
        NSArray* import = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"roomBeacons" ofType:@"json"]] options:0 error:NULL];
        if (import) {
            [_beaconStore import:import];
        }
        
        _delegates = [NSMutableDictionary dictionary];
        _lastRangeTime = [NSDate dateWithTimeIntervalSinceNow:-kSaveInterval];
    }
    return self;
}

- (NSMutableDictionary*) beaconForId:(NSString*)beaconId
{
    NSUInteger beaconIdx = [self.beacons indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[[obj beaconId] uppercaseString] isEqualToString:[beaconId uppercaseString]];
    }];
    NSMutableDictionary* beacon = beaconIdx != NSNotFound ? self.beacons[beaconIdx] : nil;
    if (self.useMock && !beacon) {
        beacon = [@{kBeaconId:beaconId,@"name":@"B1"} mutableCopy];
    }
    return beacon;
}

- (void) usersAtBeacon:(NSString*)beaconId completion:(void(^)(NSArray* users, NSError* error))completion
{
    if (!beaconId || ![KCSUser activeUser]) {
        completion(@[],nil);
        return;
    }
    
    NSTimeInterval recency = -60.0 * self.activeRecency;
    NSDate* timeToCheckForActive = [NSDate dateWithTimeIntervalSinceNow:recency];
    
    NSDictionary* params = @{@"sincetime":timeToCheckForActive, @"beaconId":beaconId};
    
    if ([KCSUser activeUser]) {
        [KCSCustomEndpoints callEndpoint:@"usersAtBeacon" params:params completionBlock:^(id results, NSError *error) {
            completion(results, error);
        }];
    } else {
        completion(@[],nil);
    }
}

- (void) allUsers:(void(^)(NSArray* users, NSError* error))completion
{
    [self usersAtBeacon:@"ALL" completion:completion];
}

- (void) nearbyUsers:(void(^)(NSArray* users, NSError* error))completion
{
    NSDictionary* beaconInfo = [KCSUser activeUser].nearestBeaconInfo;
    NSDate* timestamp = beaconInfo[@"timestamp"];
    
    NSTimeInterval recency = -60. * self.activeRecency;
    if ([timestamp timeIntervalSinceNow] > recency) {
        NSString* beaconId = beaconInfo[@"id"];
        [self usersAtBeacon:beaconId completion:completion];
    }
}

- (void)setActiveUserDirty
{
    [KCSUser activeUser].dirty = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDirtyUpdateInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([KCSUser activeUser] != nil && [KCSUser activeUser].dirty) {
            [[KCSUser activeUser] saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                if (!errorOrNil) {
                    [self setActiveUserDirty];
                } else {
                    [KCSUser activeUser].dirty = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdated object:[KCSUser activeUser] userInfo:nil];
                }
            }];
        }
    });
}

#pragma mark - The Event
- (void) getBeaconsAtEvent:(NSString*)eventId completion:(dispatch_block_t)completionBlock
{
    KCSQuery* query = [KCSQuery query];//[KCSQuery queryOnField:@"event" withExactMatchForValue:eventId];
    [_beaconStore queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (!errorOrNil) {
            NSArray* realObjects = [objectsOrNil filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@",@"event",eventId]];
            self.beacons = realObjects;
            completionBlock();
        } else {
            if ([errorOrNil.domain isEqualToString:NSURLErrorDomain]) {
                [NSTimer scheduledTimerWithTimeInterval:5 * 60 target:self selector:@selector(getBeaconsOnTimer:) userInfo:@{@"eventId":eventId,@"completion":[completionBlock copy]} repeats:NO];
            }
            completionBlock();
        }
    } withProgressBlock:nil];
}

- (void)getBeaconsOnTimer:(NSTimer*)timer
{
    NSDictionary* userInfo = timer.userInfo;
    [self getBeaconsAtEvent:userInfo[@"eventId"] completion:userInfo[@"completion"]];
}

- (void)startMonitoringAtEvent:(NSString *)eventId callback:(void(^)(BOOL started))callback
{
    [self getBeaconsAtEvent:eventId completion:^{
        NSArray* beaconUUIDs = [self.beacons valueForKeyPath:kBeaconUUID];
        NSSet* uuids = [NSSet setWithArray:beaconUUIDs];
        BOOL didStart = NO;
        for (NSString* uuid in uuids) {
            NSError* error = nil;
            BOOL started = [self.beaconManager startMonitoringForRegion:uuid identifier:[NSString stringWithFormat:@"%@.%@",eventId,uuid] error:&error];
            didStart = didStart || started;
            if (!started) {
                for (ModelErrorCallback c in self.delegates[EventErrorStarting]) {
                    c(self, error);
                }
            }
        }
        callback(didStart);
    }];
}

#pragma mark - Beacons

- (void)newNearestBeacon:(CLBeacon *)beacon
{
    if ([KCSUser activeUser]) {
        self.activeBeacon = [beacon kcsBeaconInfo];
        [KCSUser activeUser].nearestBeaconInfo = [beacon kcsBeaconInfo];
        [[KCSUser activeUser] saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            if (!errorOrNil) {
                [KCSUser activeUser].dirty = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdated object:[KCSUser activeUser] userInfo:nil];
            }
        }];
        
        for (ModelCallback c in self.delegates[EventNewClosestBeacon]) {
            c(self);
        }
    }
}

- (void)rangedBeacon:(CLBeacon *)beacon
{
    if ([self.activeBeacon isEqual:[beacon kcsBeaconInfo]] && [KCSUser activeUser]) {
        [self.activeBeacon mergeWithNewInfo:[beacon kcsBeaconInfo]];
        
        NSDate* now = [NSDate date];
        NSTimeInterval sinceLast = [now timeIntervalSinceDate:self.lastRangeTime];
        
        for (ModelErrorCallback c in self.delegates[EventRangedClosestBeacon]) {
            c(self, nil);
        }
        
        
        if (sinceLast >= kSaveInterval) {
            self.lastRangeTime = now;
            for (ModelCallback c in self.delegates[EventRangedClosestAfterReasonableTime]) {
                c(self);
            }
            
            [KCSUser activeUser].nearestBeaconInfo = self.activeBeacon;
            [[KCSUser activeUser] saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                if (!errorOrNil) {
                    [KCSUser activeUser].dirty = NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdated object:[KCSUser activeUser] userInfo:nil];
                }
            }];
            
        }
        
    }
    
}

- (void)rangingFailedForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    if ([error.domain isEqualToString:kCLErrorDomain] && (error.code == kCLErrorRangingFailure || error.code == kCLErrorRangingUnavailable || error.code == kCLErrorDenied)) {
        for (ModelErrorCallback c in self.delegates[EventRangedClosestBeacon]) {
            c(self, error);
        }
    }
}

- (void)enteredRegion:(CLBeaconRegion *)region
{
    if (!self.atConference) {
        self.atConference= YES;
        BOOL postNote = YES;
        for (UILocalNotification* ln in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
            if ([ln.userInfo[@"type"] isEqualToString:@"weclome"]) {
                postNote = NO;
                break;
            }
        }
        
        if (postNote) {
            NSDate *lastWelcome = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastWelcome"];
            if (lastWelcome) {
                NSCalendar* c = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDateComponents* lc = [c components:NSDayCalendarUnit fromDate:lastWelcome];
                NSDateComponents* dc = [c components:NSDayCalendarUnit fromDate:[NSDate date]];
                
                if (lc.day == dc.day) postNote = NO;
            }
            
        }

        if (postNote) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastWelcome"];
            UILocalNotification* note = [[UILocalNotification alloc] init];
            note.alertBody = @"Welcome to Gluecon!";
            note.userInfo = @{@"type":@"welcome"};
            [[UIApplication sharedApplication] presentLocalNotificationNow:note];
        }
    }
}

- (void)exitedRegion:(CLBeaconRegion *)region
{
    self.atConference = NO;
}

#pragma mark - delegates

- (void)registerForEvent:(NSString *)eventId callback:(id)callback
{
    NSMutableArray* arr = self.delegates[eventId];
    if (!arr) {
        arr = [NSMutableArray array];
        self.delegates[eventId] = arr;
    }
    [arr addObject:[callback copy]];
    
    if (([eventId isEqualToString:EventNewClosestBeacon] || [eventId isEqualToString:EventRangedClosestAfterReasonableTime]) && self.activeBeacon) {
        ((ModelCallback)callback)(self);
    }
}
@end
