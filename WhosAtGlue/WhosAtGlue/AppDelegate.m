
//
//  AppDelegate.m
//  WhosAtGlue
//
//  Created by Michael Katz on 2/28/14.
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

#import "AppDelegate.h"

#import <KinveyKit/KinveyKit.h>
#import "LoginViewController.h"
#import "MainViewController.h"

#import "BeaconModel.h"
#import "PushWrapper.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#pragma mark - App Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    KCSClientConfiguration* configuration = [KCSClientConfiguration configurationWithAppKey:@"kid_eTsDEAHsI9"
                                                                                     secret:@"d769fbfbbc3e4966a27c61b5497bbfe4"
                                                                                    options:@{KCS_LINKEDIN_SECRET_KEY:@"<#LinkedIn Secret Key#>",
                                                                                              KCS_LINKEDIN_API_KEY:@"<#LinkedIn API Key#>",
                                                                                              KCS_LINKEDIN_ACCEPT_REDIRECT:@"<#LinkedIn Accept URL#>",
                                                                                              KCS_LINKEDIN_CANCEL_REDIRECT:@"<#LinkedIn Cancel URL#>"}];

    [[KCSClient sharedClient] initializeWithConfiguration:configuration];
    
    self.eventModel = [[EventModel alloc] init];
    
   
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    UIStoryboard* mainboard = [UIStoryboard storyboardWithName:@"MainFlow" bundle:nil];
    self.window.rootViewController = [mainboard instantiateInitialViewController];
    
    if (![KCSUser activeUser]) {
        [self login];
    } else {
        [[KCSUser activeUser] refreshFromServer:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdated object:[KCSUser activeUser]];
        }];
        
    }
    
    [self.window makeKeyAndVisible];
    [self startListening];
    return YES;
}

- (void) login
{
    LoginViewController* lvc = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    UINavigationController* n = (UINavigationController*) self.window.rootViewController;
    [n pushViewController:lvc animated:NO];
}

#pragma mark - local notifications

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSDictionary* userInfo = notification.userInfo;
    if ([userInfo[@"type"] isEqualToString:@"goodbye"]) {
        UIViewController* rvc = self.window.rootViewController;
        MainViewController* mvc = (MainViewController*)[(UINavigationController*)rvc viewControllers][0];
        [mvc conferenceIsOver];

    }
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark - remote notification

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [PushWrapper didNotRegister:error];
    [[KCSPush sharedPush] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[KCSPush sharedPush] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken completionBlock:^(BOOL success, NSError *error) {
        if (error) {
            [PushWrapper didNotRegister:error];
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    UIViewController* rvc = self.window.rootViewController;
    if ([rvc isKindOfClass:[UINavigationController class]] && [[(UINavigationController*)rvc viewControllers][0] isKindOfClass:[MainViewController class]]) {
        UserListTableViewController* userlist = [(MainViewController*)[(UINavigationController*)rvc viewControllers][0] userList];
        [userlist refresh:YES];
    }
}


#pragma mark - network
- (void)startListening
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(show) name:KCSNetworkConnectionDidStart object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hide) name:KCSNetworkConnectionDidEnd object:nil];
}
- (void) show
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}
- (void) hide
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
@end
