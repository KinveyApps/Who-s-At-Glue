//
//  MainViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/21/14.
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
#import "MainViewController.h"
#import "UserListTableViewController.h"
#import "DistanceViewController.h"
#import "SettingsTableViewController.h"
#import "PlaygroundViewController.h"

#import "ProgressHUD.h"
#import "KCSIBeacon.h"
#import "BeaconModel.h"
#import "EventModel.h"
#import "KCSUser+WhosAtGlue.h"
#import "AppDelegate.h"

#import "AJNotificationView.h"
#import "NSError+WhosAtGlue.h"

#define kEventId @"531b025f441e63704105eaf3"
#define kKinveyBoothId @""

@interface MainViewController ()
@property (nonatomic, strong) NSTimer* notStartedTimer;
@property (nonatomic) BOOL hadErrorLoading;
- (UserListTableViewController*)userList;
@end

@interface TLTransitionAnimator : UIPercentDrivenInteractiveTransition <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>
@property (nonatomic) BOOL presenting;
@property (nonatomic) BOOL interactive;
@property (nonatomic, strong) MainViewController* parentViewController;
@property (nonatomic, strong) id<UIViewControllerContextTransitioning> transitionContext;
@end


@implementation TLTransitionAnimator

-(id)initWithParentViewController:(MainViewController *)viewController {
    if (!(self = [super init])) return nil;
    
    _parentViewController = viewController;
    
    return self;
}

-(void)userDidPan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.parentViewController.view];
    CGPoint velocity = [recognizer velocityInView:self.parentViewController.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // We're being invoked via a gesture recognizer – we are necessarily interactive
        self.interactive = YES;
        
        // The side of the screen we're panning from determines whether this is a presentation (up) or dismissal (down)
        if (location.y > CGRectGetMidY(recognizer.view.bounds)) {
            self.presenting = YES;
            PlaygroundViewController *viewController = [[PlaygroundViewController alloc] init];
            viewController.modalPresentationStyle = UIModalPresentationCustom;
            viewController.transitioningDelegate = self;
            [viewController setUsers:[self.parentViewController userList].users];
            [self.parentViewController presentViewController:viewController animated:YES completion:nil];
        }
        else {
            [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // Determine our ratio between the left edge and the right edge. This means our dismissal will go from 1...0.
        CGFloat ratio = location.y / CGRectGetHeight(self.parentViewController.view.bounds);
        [self updateInteractiveTransition:ratio];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Depending on our state and the velocity, determine whether to cancel or complete the transition.
        if (self.presenting) {
            if (velocity.y < 0) {
                [self finishInteractiveTransition];
            }
            else {
                [self cancelInteractiveTransition];
            }
        } else {
            if (velocity.y > 0) {
                [self finishInteractiveTransition];
            }
            else {
                [self cancelInteractiveTransition];
            }
        }
    }
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}


- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id <UIViewControllerAnimatedTransitioning>)animator
{
    if (self.interactive) {
        return self;
    }
    
    return nil;
}

- (id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator
{
    if (self.interactive) {
        return self;
    }
    
    return nil;
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect frame = [[transitionContext containerView] bounds];
    
    if (self.presenting)
    {
        // The order of these matters – determines the view hierarchy order.
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        frame.origin.y = [(MainViewController*)_parentViewController bottomView].frame.origin.y - 50;//CGRectGetHeight([[transitionContext containerView] bounds]);
    } else {
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
    }
    
    toViewController.view.frame = frame;
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Presenting goes from 0...1 and dismissing goes from 1...0
    CGFloat boundsHeight =  CGRectGetHeight([[transitionContext containerView] bounds]);
    CGRect frame = CGRectOffset([[transitionContext containerView] bounds], 0,boundsHeight * percentComplete-20);
    frame.origin.y = MIN( frame.origin.y, boundsHeight - 70 );
    
    if (self.presenting) {
        toViewController.view.frame = frame;
    } else {
        fromViewController.view.frame = frame;
    }
}

- (void)finishInteractiveTransition
{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect bounds = [[self.transitionContext containerView] bounds];
    
    if (self.presenting)
    {
        CGRect endFrame = bounds;
        
        [UIView animateWithDuration:0.5f animations:^{
            toViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        CGRect endFrame = CGRectOffset(bounds, 0, CGRectGetHeight(bounds));
        
        [UIView animateWithDuration:0.5f animations:^{
            fromViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

- (void)cancelInteractiveTransition
{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect bounds = [[self.transitionContext containerView] bounds];
    
    if (self.presenting) {
        CGRect endFrame = CGRectOffset(bounds, 0, CGRectGetHeight(bounds));
        CGRect unFrame = endFrame;
        unFrame.origin.y -= 70;
        
        [UIView animateWithDuration:0.4f animations:^{
            //            toViewController.view.alpha = 0;
            toViewController.view.frame = unFrame;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3f animations:^{
                toViewController.view.alpha = 0;
            } completion:^(BOOL finished) {
                toViewController.view.alpha = 1;
                toViewController.view.frame = endFrame;
                [transitionContext completeTransition:NO];
            }];
        }];
    } else {
        CGRect endFrame = bounds;
        
        [UIView animateWithDuration:0.5f animations:^{
            fromViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:NO];
        }];
    }
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    if (self.interactive) {
        // nop as per documentation
    } else {
        // This code is lifted wholesale from the TLTransitionAnimator class
        UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        
        CGRect endFrame = [[transitionContext containerView] bounds];
        
        if (self.presenting) {
            // The order of these matters – determines the view hierarchy order.
            [transitionContext.containerView addSubview:fromViewController.view];
            [transitionContext.containerView addSubview:toViewController.view];
            
            CGRect startFrame = endFrame;
            startFrame.origin.y -= CGRectGetHeight([[transitionContext containerView] bounds]);
            
            toViewController.view.frame = startFrame;
            
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                toViewController.view.frame = endFrame;
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }
        else {
            [transitionContext.containerView addSubview:toViewController.view];
            [transitionContext.containerView addSubview:fromViewController.view];
            
            endFrame.origin.y -= CGRectGetHeight([[transitionContext containerView] bounds]);
            
            [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
                fromViewController.view.frame = endFrame;
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }
    }
}
@end

@interface MainViewController ()  <UIDynamicAnimatorDelegate, UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) id interactor;

@property (nonatomic, strong) UILabel* infoLabel;
@property (nonatomic, copy) NSDictionary* lastBeacon;
@property (nonatomic, strong) AJNotificationView* panel;
@property (nonatomic, strong) NSDate* lastKinveyShownTime;
@property (nonatomic) BOOL atBoothForPopup;
@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.interactor = [[TLTransitionAnimator alloc] initWithParentViewController:self];

    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self.interactor action:@selector(userDidPan:)];
    [self.bottomView addGestureRecognizer:pan];
    
//#if IN_DEVELOPMENT
//    UITapGestureRecognizer* dblTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showKinvey)];
//    dblTap.numberOfTapsRequired = 2;
//    [self.bottomView addGestureRecognizer:dblTap];
//#endif

    UIBarButtonItem* back = [[UIBarButtonItem alloc] initWithTitle:@"HOME" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = back;
    
    DistanceViewController* btm = [self bottomController];
    [self dealWithNoDistance];
    btm.radiusView.loading = YES;
    
    [self setupInfoLabel];
    self.infoLabel.text = @"Loading conference info...";
    EventModel* model = [(AppDelegate*)[UIApplication sharedApplication].delegate eventModel];
    [model atSetup:^(){[self afterEventInit:model];}];
}

- (void) dealWithNoDistance
{
    DistanceViewController* btm = [self bottomController];
    btm.disabled = YES;
    btm.radiusView.loading = NO;
}

- (void) afterEventInit:(EventModel*)model
{
    [ProgressHUD dismiss];
    if ([model timeYet] > 0) {
        [self conferenceIsOver];
        return;
    }
    [[BeaconModel model] registerForEvent:EventErrorStarting callback:^(BeaconModel* model, NSError* error) {
        self.hadErrorLoading = YES;
        if ([error.domain isEqualToString:KCSIBeaconErrorDomain]) {
            [self setupInfoLabel];
            
            if (error.code == KCSIBeaconCannotMonitorCLBeaconRegion || error.code == KCSIBeaconCannotRangeIBeacons || error.code == KCSIBeaconLocationServicesRestricted) {
                self.infoLabel.text = @"iBeacon technology is unavailable for this device. Please visit the Kinvey booth for a demonstration.";
            } else if (error.code == KCSIBeaconLocationServicesDenied || error.code == KCSIBeaconLocationServicesNotEnabled) {
                self.infoLabel.text = @"Location Services is disabled. Re-enable in the Settings app to use this application.";
            } else {
                [error alert:@"Unable to start Beacon service" vc:self];
            }
        } else {
            [error alert:@"Unable to start Beacon service" vc:self];
        }
        [self dealWithNoDistance];
    }];
    
    [[BeaconModel model] startMonitoringAtEvent:kEventId callback:^(BOOL started) {
        if (started) {
            [self waitForConferenceStuff:model];
            DistanceViewController* btm = [self bottomController];
            btm.disabled = YES;
            
        }
    }];
    
    [[BeaconModel model] registerForEvent:EventNewClosestBeacon callback:^(BeaconModel *model) {
        DistanceViewController* btm = [self bottomController];
        btm.radiusView.loading = NO;
        
        NSDictionary* beaconInfo = [model beaconForId:model.activeBeacon.plistObject.beaconId];
        if (!self.lastBeacon) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideInfoLabel];
                [self hideOverlay];
            });
        }
        self.lastBeacon = beaconInfo;
        NSString* boothId = beaconInfo[@"booth"];
        BOOL alreadyAtPopupBooth = self.atBoothForPopup;
        self.atBoothForPopup = [boothId isEqualToString:kKinveyBoothId];
        if (alreadyAtPopupBooth && !self.atBoothForPopup) {
            //went away from Kinvey
            [self hideKinvey]; 
        }
    }];
    
    [[BeaconModel model] registerForEvent:EventRangedClosestBeacon callback:^(BeaconModel *tmodel, NSError* error) {
        if (self.atBoothForPopup && tmodel.activeBeacon.accuracy <= model.boothPopupAccuracy) {
            self.atBoothForPopup = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showKinvey];
            });
        }
         if ([error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorDenied) {
            [self setupInfoLabel];
             self.infoLabel.text = @"Location Services is disabled. Re-enable in the Settings app to use this application.";
             self.lastBeacon = nil;
         } else if ([error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorRangingUnavailable) {
             [self setupInfoLabel];
             self.infoLabel.text = @"iBeacon ranging unvailable. Make sure bluetooth is turned on and location services is enabled.";
             self.lastBeacon = nil;
             
         }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UserUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if ([self userList].users.count > 0) {
            [self hideInfoLabel];
            [self hideOverlay];
        }
    }];
}

- (void) waitForConferenceStuff:(EventModel*)model
{
    NSInteger t = [model timeYet];
    if (t < 0) {
        [self conferenceNotStarted];
    } else if (t > 0) {
        [self conferenceIsOver];
    } else {
        if (self.lastBeacon == nil && !self.hadErrorLoading) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupOverlay];
                [self conferenceStarting];
            });
        }

    }
    if (t <= 0) {
        //post a note when it's done.
        BOOL postNote = YES;
        for (UILocalNotification* ln in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
            if ([ln.userInfo[@"type"] isEqualToString:@"goodbye"]) {
                postNote = NO;
                break;
            }
        }
        
        if (postNote) {
            UILocalNotification* note = [[UILocalNotification alloc] init];
            note.alertBody = @"Thank you for visiting gluecon";
            note.userInfo = @{@"type":@"goodbye"};
            note.fireDate = [model endDate];
            [[UIApplication sharedApplication] scheduleLocalNotification:note];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.infoLabel.frame = self.view.bounds;
}

#pragma mark - Navigation

- (IBAction)showSettings:(id)sender
{
    UIStoryboard* settings = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIViewController* v = [settings instantiateInitialViewController];
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:v];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        v.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissSettings)];
        [self presentViewController:nc animated:YES completion:nil];
    } else {
        [self.navigationController pushViewController:[settings instantiateInitialViewController] animated:YES];
    }
}

- (void) dismissSettings
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Filtering
- (IBAction)changeFilter:(UISegmentedControl*)sender
{
    [self userList].filter = sender.selectedSegmentIndex;
}

- (UserListTableViewController*)userList
{
    for (id v in self.childViewControllers) {
        if ([v isKindOfClass:[UserListTableViewController class]]) {
            return v;
        }
    }
    return nil;
}

- (DistanceViewController*)bottomController
{
    for (id v in self.childViewControllers) {
        if ([v isKindOfClass:[DistanceViewController class]]) {
            return v;
        }
    }
    return nil;
}


#pragma mark - Time and Relative Dimension In Spaaaaace

- (void) enableFilter:(BOOL) enabled
{
    self.filterItem.enabled = enabled;
    self.filterSwitch.enabled = enabled;
    [self.filterSwitch setEnabled:enabled forSegmentAtIndex:0];
    [self.filterSwitch setEnabled:YES forSegmentAtIndex:1];
    if (enabled) {
        [self.filterSwitch setSelectedSegmentIndex:self.userList.filter];
    } else {
        self.userList.nouserslabel.hidden = YES;
    }
}

- (void) setupInfoLabel
{
    [self.infoLabel removeFromSuperview];
    
    self.infoLabel = [[UILabel alloc] initWithFrame:self.userList.view.frame];
    self.infoLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.infoLabel.textColor = [UIColor whiteColor];
    self.infoLabel.font = [UIFont boldSystemFontOfSize:28.];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.userInteractionEnabled = YES;
    self.infoLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.infoLabel.userInteractionEnabled = YES;
    [self.view addSubview:self.infoLabel];

#if IN_DEVELOPMENT
    UITapGestureRecognizer* dblTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideInfoLabel)];
    dblTap.numberOfTapsRequired = 2;
    //    dblTap.numberOfTouchesRequired = 2;
    [self.infoLabel addGestureRecognizer:dblTap];
#endif
    
    [self hideOverlay];
    self.userList.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.userList.tableView reloadData];
    [self enableFilter:NO];
}

- (void) hideInfoLabel
{
    self.infoLabel.hidden = NO;
    [self.infoLabel removeFromSuperview];
    self.userList.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.userList.tableView reloadData];
    [self enableFilter:YES];
}

- (void) setupOverlay
{
    [self hideInfoLabel];
    
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.overlayView.hidden = NO;
    [self enableFilter:NO];
    
    self.infoLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.infoLabel.textColor = [UIColor whiteColor];
    self.infoLabel.font = [UIFont boldSystemFontOfSize:28.];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.numberOfLines = 0;
    
    self.userList.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.userList.tableView reloadData];
}

- (void) hideOverlay
{
    self.overlayView.hidden = YES;
    self.userList.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.userList.tableView reloadData];
    [self enableFilter:YES];
}

- (void) conferenceNotStarted
{
    [self setupOverlay];
    [self updateNotStartedString];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conferenceStarting) name:ConferenceStartingNotification object:nil];
    self.notStartedTimer = [NSTimer scheduledTimerWithTimeInterval:ONE_MINUTE target:self selector:@selector(updateNotStartedString) userInfo:nil repeats:YES];
}

- (void)updateNotStartedString
{
    EventModel* model = [(AppDelegate*)[UIApplication sharedApplication].delegate eventModel];
    NSDate* startDate = [model startDate];
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate* now = [NSDate date];
    if ([startDate compare:now] == NSOrderedAscending) {
        [self conferenceStarting];
    } else {
        NSDateComponents* components = [gregorian components:NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit fromDate:now toDate:startDate options:0];
        self.overlayLabel.text = [NSString stringWithFormat:@"Gluecon hasn't started yet\n%li days %li hours %li minutes",(long)components.day,(long)components.hour,(long)components.minute];
    }
}

- (void) conferenceStarting
{
    [self.notStartedTimer invalidate];
    self.overlayLabel.text = @"Gluecon is going on, but you're not there yet.";
}

- (void) conferenceIsOver
{
    [self setupInfoLabel];
    self.infoLabel.text = [NSString stringWithFormat:@"Gluecon is over!\n\nTap Here to find out more about Kinvey, beacons, or to get this app's source code."];
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapinfolabel:)];
    [self.infoLabel addGestureRecognizer:tap];
}

- (void) tapinfolabel:(UITapGestureRecognizer*)tap
{
    if (tap.state == UIGestureRecognizerStateRecognized) {
        NSString* url = [[(AppDelegate*)[UIApplication sharedApplication].delegate eventModel] portalURL];
        if (url) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
    }
}

#pragma mark - Kinvey

- (void) showKinvey
{
    if (!self.lastKinveyShownTime || [self.lastKinveyShownTime timeIntervalSinceNow] < -ONE_HOUR) {
        [self hideKinvey];
        self.panel = [AJNotificationView showNoticeInView:[[[UIApplication sharedApplication] delegate] window]
                                                     type:AJNotificationTypeOrange
                                                    title:@"You're near the Kinvey booth! Come talk to us."
                                          linedBackground:AJLinedBackgroundTypeStatic
                                                hideAfter:ONE_MINUTE
                                                 response:^{
                                                     self.panel = nil;
                                                     UIStoryboard* board = [UIStoryboard storyboardWithName:@"KinveyInfo" bundle:nil];
                                                     [self presentViewController:[board instantiateInitialViewController] animated:YES completion:nil];
                                                 }];
        [self.panel setImage:[UIImage imageNamed:@"Kinvey"]];
        self.lastKinveyShownTime = [NSDate date];
    }
}

- (void) hideKinvey
{
    if (self.panel) {
        [self.panel hide];
    }
}

@end
