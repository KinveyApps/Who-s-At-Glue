//
//  Info2TableViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/18/14.
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

#import "Info2TableViewController.h"
#import "AppDelegate.h"
#import "M13Checkbox.h"
#import "ProgressHUD.h"

#import "KCSUser+WhosAtGlue.h"
#import "BeaconModel.h"


@interface Info2TableViewController ()
@property (nonatomic, strong) NSArray* interests;
@property (nonatomic, strong) NSMutableArray* selectedToLearns;
@property (nonatomic, strong) NSMutableArray* selectedToTalks;
@end

@implementation Info2TableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor backgroundColor];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.interests = [[(AppDelegate*)[UIApplication sharedApplication].delegate eventModel] interests];
    
    self.selectedToLearns = [NSMutableArray array];
    self.selectedToTalks = [NSMutableArray array];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.interests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIColor* theColor = [UIColor darkTextColor];
    NSString* interest = self.interests[indexPath.row];
    UILabel* l = (UILabel*)[cell.contentView viewWithTag:3];
    l.text = interest;
    l.textColor = theColor;

    
    M13Checkbox* cb1 = (M13Checkbox*)[cell.contentView viewWithTag:1];
    cb1.checkAlignment = M13CheckboxAlignmentRight;
    cb1.checkColor = theColor;
    cb1.uncheckedColor = [UIColor clearColor];
    cb1.strokeColor = theColor;
    cb1.tintColor = [UIColor clearColor];
    cb1.checkState = [self.selectedToLearns containsObject:interest] ? M13CheckboxStateChecked : M13CheckboxStateUnchecked;

    M13Checkbox* cb2 = (M13Checkbox*)[cell.contentView viewWithTag:2];
    cb2.checkAlignment = M13CheckboxAlignmentRight;
    cb2.checkColor = theColor;
    cb2.uncheckedColor = [UIColor clearColor];
    cb2.strokeColor = theColor;
    cb2.tintColor = [UIColor clearColor];
    cb2.checkState = [self.selectedToTalks containsObject:interest] ? M13CheckboxStateChecked : M13CheckboxStateUnchecked;

    
    return cell;
}

- (IBAction)checkboxed:(M13Checkbox*)sender
{
    self.navigationItem.rightBarButtonItem.title = @"Next";
    NSMutableArray* a = sender.tag == 1 ? self.selectedToLearns : self.selectedToTalks;
    
    CGPoint p = [self.tableView convertPoint:sender.center fromView:sender.superview];
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:p];

    NSString* title = self.interests[indexPath.row];
    
    if (sender.checkState == M13CheckboxStateChecked) {
        [a addObject:title];
    } else {
        [a removeObject:title];
    }
    
}

- (IBAction)next:(id)sender
{
    [ProgressHUD show:@"Please wait..."];
    
    [KCSUser activeUser].setup = YES;
    [KCSUser activeUser].learnInterests = self.selectedToLearns;
    [KCSUser activeUser].talkInterests = self.selectedToTalks;
    [[KCSUser activeUser] saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil) {
            [[BeaconModel model] setActiveUserDirty];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdated object:[KCSUser activeUser]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressHUD dismiss];
            UIViewController* top = self.presentingViewController.presentingViewController ? self.presentingViewController.presentingViewController : self.presentingViewController;
            [top dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

@end
