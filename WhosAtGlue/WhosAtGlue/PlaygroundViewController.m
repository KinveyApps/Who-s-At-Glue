//
//  PlaygroundViewController.m
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
#import "PlaygroundViewController.h"
#import "BarGraphCell.h"
#import "TimeHeaderView.h"

#import "BeaconModel.h"
#import "KCSBeaconInfo+WhosAtGlue.h"

@interface PlaygroundViewController ()
@property (nonatomic, strong) NSMutableArray* rows;

@property (nonatomic, copy) NSDictionary* values;
@property (nonatomic) float maxValue;
@property (nonatomic, copy) NSArray* timeStamps;
@property (nonatomic) BOOL firstLoaded;

@property (nonatomic, strong) TimeHeaderView* header;
@end

@implementation PlaygroundViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.rows = [NSMutableArray array];
    [self dealWithNoDistance];
    [self showMock];

    self.toolbar.clipsToBounds = YES;
    self.sampleDataLabel.transform = CGAffineTransformMakeRotation(-M_PI_4);
    self.sampleDataLabel.shadowColor = [UIColor blackColor];
    self.sampleDataLabel.shadowOffset = CGSizeMake(1, 1);
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[BarGraphCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.explainTextView.backgroundColor = [UIColor clearColor];
    self.explainTextView.contentInset = UIEdgeInsetsMake(8, 0, 0, 0);
    
    self.header = [[TimeHeaderView alloc] init];
    self.header.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 50);
    self.tableView.tableHeaderView = self.header;
    [(UITextView*)self.tableView.tableFooterView setDelegate:self];
    
    [[BeaconModel model] registerForEvent:EventNewClosestBeacon callback:^(BeaconModel *model) {
        NSString* beacon = model.activeBeacon.plistObject.beaconId;
        self.radiusview.disabled = NO;
        if (beacon) {
            NSDictionary* beaconInfo = [model beaconForId:beacon];
            self.radiusview.title = beaconInfo[@"name"];
        }
    }];
    [[BeaconModel model] registerForEvent:EventRangedClosestBeacon callback:^(BeaconModel *model, NSError* error) {
        if (!error) {
            self.radiusview.disabled = NO;
            self.radiusview.animated = YES;
            self.radiusview.distance = model.activeBeacon.accuracy;
        } else {
            self.radiusview.disabled = YES;
            self.radiusview.animated = NO;
        }
    }];
    [[BeaconModel model] registerForEvent:EventRangedClosestAfterReasonableTime callback:^(BeaconModel *model) {
        [model usersAtBeacon:model.activeBeacon.plistObject.beaconId completion:^(NSArray *users, NSError *error) {
            if (!error) {
                [self setUsers:users];
            }
        }];
    }];

    [[BeaconModel model] registerForEvent:EventErrorStarting callback:^(BeaconModel* model, NSError* error) {
        [self dealWithNoDistance];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated]; 
    if ([KCSUser activeUser]) {
        [KCSCustomEndpoints callEndpoint:@"bargraph" params:nil completionBlock:^(id results, NSError *error) {
            if (!error) {
                [self handleResults:results];
            } else {
                //Do nothing either show stale data or show sample until things can be properly refreshed
            }
        }];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self updateTableViewHeaderViewHeight];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateTableViewHeaderViewHeight];
}

- (IBAction)close:(id)sender
{
    id x = [(UINavigationController*)self.presentingViewController viewControllers][0];
    [x dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - radius view

- (void)setUsers:(NSArray *)users
{
    [self.radiusview setUsers:users];
}


- (void) dealWithNoDistance
{
    self.radiusview.disabled = YES;
    self.radiusview.animated = NO;
    self.radiusview.title = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    BarGraphCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UIColor* color = !self.firstLoaded ? [UIColor lightGrayColor] : [UIColor foregroundColor];
    cell.tintColor = color;
    cell.barGraph.tintColor = color;

    NSString* beaconId = self.rows[indexPath.row];
    NSDictionary* value = self.values[beaconId];

    NSString* name = value[@"name"];
    if (!name) {
        NSDictionary* beaconInfo = [[BeaconModel model] beaconForId:beaconId];
        name = beaconInfo[@"name"];
    }
    
    [cell setTitle:name];
    cell.barGraph.data = value[@"users"];
    cell.barGraph.maxValue = self.maxValue;
    
    return cell;
}

- (void) showMock
{
    self.rows = [@[@"B1",@"B2",@"B3"] mutableCopy];
    self.maxValue = 100;
    self.timeStamps = @[@"9:30 AM"];
    
    NSMutableDictionary* mockValues = [NSMutableDictionary dictionary];
    for (NSString* key in self.rows) {
        NSUInteger count = 24 * 2 * 3;
        NSMutableArray* arr = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [arr addObject:@(arc4random_uniform(self.maxValue))];
        }
        mockValues[key] = @{@"users":arr,@"name":key};
    }
    self.values = mockValues;
    self.header.times = self.timeStamps;
    self.sampleDataLabel.hidden = NO;
}

- (void) handleResults:(NSDictionary*)results
{
    self.maxValue = 0;
    self.timeStamps = @[];
    [self.rows removeAllObjects];
    self.firstLoaded = YES;
    
    [results enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* beaconId = key;
        if (![beaconId isEqualToString:@"undefined"]) {
            [self.rows addObject:beaconId];
            
            NSArray* times = obj[@"timestamps"];
            if (times.count > self.timeStamps.count) {
                self.timeStamps = times;
            }

            NSArray* values = obj[@"users"];
            NSNumber* maxValue = [values valueForKeyPath:@"@max.self"];
            self.maxValue = MAX(self.maxValue, [maxValue floatValue]);
        }
    }];
    
    self.values = results;

    self.header.times = self.timeStamps;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sampleDataLabel.hidden = YES;
        [self.tableView reloadData];
        [self updateTableViewHeaderViewHeight];
    });
}

/**
 tableView's tableViewHeaderView contains wrapper view, which height is evaluated
 with Auto Layout. Here I use evaluated height and update tableView's
 tableViewHeaderView's frame.
 
 New height for tableViewHeaderView is applied not without magic, that's why
 I call -resetTableViewHeaderView.
 And again, this doesn't work due to some internals of UITableView,
 so -resetTableViewHeaderView call is scheduled in the main run loop.
 */
- (void)updateTableViewHeaderViewHeight
{
    CGRect tableFrame = self.tableView.frame;
    
    UITextView* tv = (UITextView*) self.tableView.tableFooterView;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize t = [tv.text sizeWithFont:tv.font constrainedToSize:CGSizeMake(tv.contentSize.width - 4., CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    CGRect footerFrame = self.tableView.tableFooterView.frame;
#pragma clang diagnostic pop
    UIEdgeInsets tvInset = tv.contentInset;
    footerFrame.size.height = t.height + 2 * (tvInset.top + tvInset.bottom) + 22;
    self.tableView.tableFooterView.frame = footerFrame;
    
    CGRect headerFrame = self.tableView.tableHeaderView.frame;
    footerFrame.size.width = tableFrame.size.width;
    self.tableView.tableHeaderView.frame = headerFrame;
    
    // this magic applies the above changes
    // note, that if you won't schedule this call to the next run loop iteration
    // you'll get and error
    // so, I guess that's not a clean solution and could be wrapped in @try@catch block
    [self performSelector:@selector(resetTableViewHeaderView) withObject:self afterDelay:0];
}

- (void)resetTableViewHeaderView
{
    [UIView beginAnimations:@"tableHeaderView" context:nil];
    
    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    self.tableView.tableFooterView = self.tableView.tableFooterView;
    
    [UIView commitAnimations];
}

#pragma mark - TextView
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    return NO;
}

@end
