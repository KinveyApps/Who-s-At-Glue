//
//  PushWrapper.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/8/14.
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

#import "PushWrapper.h"

#import <KinveyKit/KinveyKit.h>
#import "KCSUser+WhosAtGlue.h"

#define kReaskTime 6 * SEC_PER_HOUR

#define kPrefAcceptedPush @"acceptedPush"
#define kPrefLastPushTime @"lastAcceptedPushTime"

@interface PushWrapper () <UIAlertViewDelegate>

@end

@implementation PushWrapper

+ (instancetype) pushWrapper
{
    static PushWrapper* pushWrapper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pushWrapper = [[self alloc] init];
    });
    return pushWrapper;
}

+ (void) register
{
    [[self pushWrapper] doRegister];
}

+ (void)didNotRegister:(NSError *)error
{
    [KCSUser activeUser].notificationsOn = @NO;
    if (error) {
        //log the data, but do nothing
        KCSAppdataStore* logStore = [KCSCachedStore storeWithCollection:[KCSCollection collectionFromString:@"pushRegisterLog" ofClass:[NSMutableDictionary class]] options:@{KCSStoreKeyOfflineUpdateEnabled : @YES}];
        [logStore saveObject:@{@"what":@"+PushWrapper didNotRegister:",@"description":error.localizedDescription, @"failureReason":error.localizedFailureReason ? error.localizedFailureReason : @""} withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            //do nothing again
        } withProgressBlock:nil];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPrefLastPushTime];
    }
}

- (void) doRegister
{
    NSDate* lastPushRequestTime = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefLastPushTime];
    if (lastPushRequestTime) {
        BOOL acceptedLast = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefAcceptedPush];
        if (acceptedLast) {
            [self registerToken];
        } else {
            if ([lastPushRequestTime timeIntervalSinceNow] < -kReaskTime) {
                [self showPrePermission];
            }
        }
    } else {
        [self showPrePermission];
    }
}

- (void) showPrePermission
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Message sent!" message:@"Would you like to be notified when someone responds or reaches out to you?" delegate:self cancelButtonTitle:@"No thanks" otherButtonTitles:@"Notify me", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSDate* lastPushTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:lastPushTime forKey:kPrefLastPushTime];
    if (buttonIndex == alertView.cancelButtonIndex) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPrefAcceptedPush];
        [KCSUser activeUser].notificationsOn = @NO;
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPrefAcceptedPush];
        [KCSUser activeUser].notificationsOn = @YES;
        [self registerToken];
    }
}

+ (void) registerToken
{
    [[self pushWrapper] registerToken];
}

- (void) registerToken
{
    [KCSPush registerForPush];
}

@end
