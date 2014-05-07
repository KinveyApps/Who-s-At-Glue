//
//  UserListTableViewController.m
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

#import "UserListTableViewController.h"
#import "BeaconModel.h"
#import "KCSUser+WhosAtGlue.h"
#import "KCSBeaconInfo+WhosAtGlue.h"

#import "UserCell.h"
#import "NSError+WhosAtGlue.h"
#import "ProgressHUD.h"

#import "EventModel.h"
#import "AppDelegate.h"
#import "PushWrapper.h"

#import "UserProfileViewController.h"

#define kCellHeight 80
#define kRefreshRate 60

@interface UserListTableViewController ()
@property (nonatomic, strong) NSArray* preFilteredUsers;
@property (nonatomic, strong) NSDate* lastRefreshTime;
@property (nonatomic) BOOL doingManualRefresh;
@property (nonatomic) BOOL showedPushAcceptance;
@end

@implementation UserListTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.nouserslabel = [[UILabel alloc] init];
    self.nouserslabel.text = @"Nobody else here yet!";
    self.nouserslabel.textAlignment = NSTextAlignmentCenter;
    CGRect nousersframe = self.view.bounds;
    nousersframe.size.height -= 60 + 64;
    self.nouserslabel.frame = nousersframe;
    [self.view addSubview:self.nouserslabel];

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(manualRefresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self refresh:YES];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UserPictureNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSString* userId = note.object;
        NSUInteger idx = [self.users indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj[KCSEntityKeyId] isEqualToString:userId];
        }];
        if (idx != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MessagesUpdatedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refresh:) object:@(NO)];
        [self performSelector:@selector(refresh:) withObject:@(NO) afterDelay:kRefreshRate];
        [self.tableView reloadData];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UserUpdated object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self refresh:NO];
    }];

    [self.tableView reloadData]; //refresh unreads
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MessagesUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UserUpdated object:nil];
}

#pragma mark - model

- (void)setFilter:(UserListFilter)filter
{
    _filter = filter;
    [ProgressHUD show:@"Updating list"];
    [self refresh:NO];
}

- (void) manualRefresh
{
    self.doingManualRefresh = YES;
    [self refresh:NO];
}

- (void) refresh:(BOOL) quiet
{
    if ([KCSUser activeUser]) {
        if (self.filter == FilterNearby) {
            [[BeaconModel model] nearbyUsers:^(NSArray *users, NSError *error) {
                [self handleAllUsers:users error:error quiet:quiet];
            }];
        } else {
            [[BeaconModel model] allUsers:^(NSArray *users, NSError *error) {
                [self handleAllUsers:users error:error quiet:quiet];
            }];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
            [ProgressHUD dismiss];
        });
    }
}

- (void) handleAllUsers:(NSArray*)users error:(NSError*)error quiet:(BOOL) quiet
{
    if (![users isKindOfClass:[NSArray class]] && !error) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD dismiss];
        if (!error) {
            self.users = [self sortUsers:users];
            [self.tableView reloadData];
        } else {
            if (self.doingManualRefresh) {
                [error alert:@"Unable to fetch users. Pull to refresh later." vc:self];
            } else {
                NSLog(@"Error refreshing users: %@", users);
            }
            [self.tableView reloadData];
        }
        self.doingManualRefresh = NO;
        [self.refreshControl endRefreshing];
        BOOL hasusers = quiet || [self.users count] > 0;
        self.nouserslabel.hidden = hasusers;
        self.tableView.separatorStyle = hasusers ? UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    });
}

- (NSArray*) sortUsers:(NSArray*)usersIn
{
    NSSet* interests = [NSSet setWithArray:[KCSUser activeUser].learnInterests];
    NSString* me = [KCSUser activeUser].userId;
    NSInteger myIndex = [usersIn indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj[KCSEntityKeyId] isEqualToString:me];
    }];
    if (myIndex != NSNotFound) {
        NSMutableArray* newUsers = [usersIn mutableCopy];
        [newUsers removeObjectAtIndex:myIndex];
        usersIn = newUsers;
    }
    return [usersIn sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
        NSArray* messages1 = obj1[@"messages"];
        NSArray* messages2 = obj2[@"messages"];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"read = false AND targetUser like %@", [KCSUser activeUser].userId];
        
        NSUInteger msgCount1 = [messages1 filteredArrayUsingPredicate:predicate].count;
        NSUInteger msgCount2 = [messages2 filteredArrayUsingPredicate:predicate].count;
        
        if (msgCount1 || msgCount2) {
            if (msgCount1 > msgCount2) return NSOrderedAscending;
            if (msgCount2 > msgCount1) return NSOrderedDescending;
            return [obj1[kFormattedName] compare:obj2[kFormattedName]];
        }

        NSMutableSet* talks1 = [NSMutableSet setWithArray:obj1[kTalkInterests]];
        [talks1 intersectSet:interests];
        NSMutableSet* talks2 = [NSMutableSet setWithArray:obj2[kTalkInterests]];
        [talks2 intersectSet:interests];
        
        NSUInteger iCount1 = [talks1 count];
        NSUInteger iCount2 = [talks2 count];
        
        if (iCount1 > iCount2) return NSOrderedAscending;
        if (iCount2 > iCount1) return NSOrderedDescending;
        return [obj1[kFormattedName] compare:obj2[kFormattedName]];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSDictionary* userDict = self.users[indexPath.row];
    cell.textLabel.text = userDict[@"formatted_name"];
    cell.detailTextLabel.text = userDict[@"headline"];
    cell.interests = [NSSet setWithArray:userDict[@"talkInterests"]];
    
    NSArray* messages = userDict[@"messages"];
    NSUInteger count = [messages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"read = false AND targetUser like %@", [KCSUser activeUser].userId]].count;
    if (count && !self.showedPushAcceptance) {
        [PushWrapper register];
    }
    
    cell.badgeString = count ? [NSString stringWithFormat:@"%lu", (unsigned long)count] : nil;
    
    cell.badgeColor = [UIColor reddishColor];
    cell.imageView.image = [KCSUser picture:userDict];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserProfileViewController* uvc = [[UserProfileViewController alloc] init];
    NSMutableDictionary* user = self.users[indexPath.row];
    uvc.user = user;
    [self.navigationController pushViewController:uvc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

@end
