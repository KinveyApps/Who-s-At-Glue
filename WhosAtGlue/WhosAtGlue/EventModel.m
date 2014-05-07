//
//  EventModel.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/19/14.
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

#import "EventModel.h"
#import <KinveyKit/KinveyKit.h>

#import "KCSUser+WhosAtGlue.h"
#import "BeaconModel.h"
#import "KCSTimeConstants.h"

NSString* const MessagesUpdatedNotification = @"MessagesUpdated";
NSString* const ConferenceStartingNotification = @"ConferenceStartingNotification";

#define kEventId <#Event _id#>
#define kUpdateIntervalShort 5 * SEC_PER_MINUTE
#define kUpdateIntervalLong  6 * SEC_PER_HOUR
#define kUpdateIntervalNormal 20 * SEC_PER_MINUTE
#define kUpdateIntervalNever DBL_MAX

#define kDefaultPopupDistance 2 //meters

@interface EventModel ()
@property (nonatomic, strong) NSMutableDictionary* eventDict;
@property (nonatomic) BOOL isSetup;
@property (nonatomic) NSMutableArray *setupCallbacks;
@property (nonatomic) NSTimer* updateTimer;
@property (nonatomic, strong) KCSCachedStore* eventStore;
@end

@implementation EventModel

- (id)init
{
    self = [super init];
    if (self) {
        _setupCallbacks = [NSMutableArray array];
        _eventStore = [KCSCachedStore storeWithCollection:[KCSCollection collectionFromString:@"events" ofClass:[NSMutableDictionary class]] options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst)}];

        [self setup];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated) name:UserUpdated object:nil];
    }
    return self;
}

- (void) setup
{
    NSArray* import = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"events" ofType:@"json"]] options:0 error:NULL];
    if (import) {
        [self.eventStore import:import];
    }

    if ([KCSUser activeUser]) {
        [self update];
    } else {
        [[NSNotificationCenter defaultCenter] addObserverForName:KCSActiveUserChangedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if ([KCSUser activeUser]) {
                [self update];
            }
        }];
    }
}

- (void) update
{
    if (![KCSUser activeUser]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KCSReachabilityChangedNotification object:nil];
    [self.updateTimer invalidate];
    
//    KCSCachedStore* eventStore = [KCSCachedStore storeWithCollection:[KCSCollection collectionFromString:@"events" ofClass:[NSMutableDictionary class]] options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst)}];
//    NSArray* import = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"events" ofType:@"json"]] options:0 error:NULL];
//    if (import) {
//        [eventStore import:import];
//    }
    [self.eventStore loadObjectWithID:kEventId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (!errorOrNil) {
            self.eventDict = objectsOrNil[0];
            NSInteger isTime = [self timeYet];
            NSTimeInterval interval;
            if (isTime < 0) {
                UILocalNotification* note = [[UILocalNotification alloc] init];
                note.alertBody = @"Gluecon will start in 1 hour.";
                NSDate* startDate = self.eventDict[@"startDate"];
                note.fireDate = [startDate dateByAddingTimeInterval:-ONE_HOUR];
                note.userInfo = @{@"type":@"startDate",@"nsnote":ConferenceStartingNotification};
                for (UILocalNotification* ln in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
                    if ([ln.userInfo[@"type"] isEqualToString:@"startDate"]) {
                        [[UIApplication sharedApplication] cancelLocalNotification:ln];
                    }
                }
                [[UIApplication sharedApplication] scheduleLocalNotification:note];
                interval = kUpdateIntervalLong;
            } else if (isTime > 0) {
                interval = kUpdateIntervalNever;
            } else {
                interval = kUpdateIntervalNormal;
            }
            [self processUpdate];
            [self scheduleUpdate:interval];
        } else {
            [self scheduleUpdate:kUpdateIntervalShort];
            if ([errorOrNil.domain isEqualToString:NSURLErrorDomain]) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:KCSReachabilityChangedNotification object:nil];
            }
        }
    } withProgressBlock:nil];
}

- (void) scheduleUpdate:(NSTimeInterval)interval
{
    [self.updateTimer invalidate];
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(update) userInfo:nil repeats:NO];
}

- (void) processUpdate
{
    self.isSetup = YES;
    for (void(^c)() in self.setupCallbacks) {
        c();
    }
}

- (void)atSetup:(void (^)())callback
{
    if (self.isSetup) {
        callback();
    } else {
        [self.setupCallbacks addObject:[callback copy]];
    }
}

#pragma mark - Event

- (NSString *)portalURL
{
    return self.eventDict[@"portalURL"];
}

- (NSArray *)interests
{
    return self.eventDict[@"interests"];
}

- (NSDate*) startDate
{
    return self.eventDict[@"startDate"];
}

- (NSDate *)endDate
{
    return self.eventDict[@"endDate"];
}

- (NSInteger) timeYet
{
    NSDate* now = [NSDate date];
    NSDate* startDate = [self startDate];
    if ([startDate compare:now] != NSOrderedDescending) {
        NSDate* endDate = [self endDate];
        if ([endDate compare:now] != NSOrderedAscending) {
            //Okay to Go
            return 0;
        } else {
            return 1; //Too late
        }
    } else {
        return -1;
    }
}

- (double)boothPopupAccuracy
{
    NSNumber* setAccuracy = self.eventDict[@"boothPopupDistance"];
    CLLocationAccuracy distance = kDefaultPopupDistance;
    if (setAccuracy && [setAccuracy doubleValue] > 0) {
        distance = [setAccuracy doubleValue];
    }
    return distance;
}

#pragma mark - User
- (void) userUpdated
{
    NSArray* unreadMessages = [KCSUser activeUser].messages;
    if (unreadMessages && unreadMessages.count > 0) {
        NSMutableOrderedSet* oldMessageIds = [NSMutableOrderedSet orderedSetWithArray:[self.unreadMessages valueForKeyPath:KCSEntityKeyId]];
        NSMutableOrderedSet* newMessageIds = [NSMutableOrderedSet orderedSetWithArray:[unreadMessages valueForKeyPath:KCSEntityKeyId]];
        [newMessageIds minusOrderedSet:oldMessageIds];
        if (newMessageIds.count > 0) {
            self.unreadMessages = [unreadMessages mutableCopy];
            [[NSNotificationCenter defaultCenter] postNotificationName:MessagesUpdatedNotification object:self];
        }
    }
}

- (NSArray*) messagesForUser:(NSString*)userId
{
    return [self.unreadMessages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K like %@ OR %K like %@", @"_acl.creator", userId, @"targetUser", userId]];
}

- (NSArray*) unreadMessagesForUser:(NSString*)userId
{
    return [self.unreadMessages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K like %@ AND read = false", @"_acl.creator", userId]];
}

- (void) markMessageAsRead:(NSMutableDictionary*)message
{
    message[@"read"] = @YES;
    KCSCollection* messagesCollection = [KCSCollection collectionFromString:@"messages" ofClass:[NSMutableDictionary class]];
    KCSCachedStore* messageStore = [KCSCachedStore storeWithCollection:messagesCollection options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst), KCSStoreKeyOfflineUpdateEnabled : @YES}];
    [messageStore saveObject:message withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        [self.unreadMessages removeObject:message];
         [[NSNotificationCenter defaultCenter] postNotificationName:MessagesUpdatedNotification object:self];
    } withProgressBlock:nil];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

}

@end
