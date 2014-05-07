//
//  NSError+WhosAtGlue.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/11/14.
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

#import "NSError+WhosAtGlue.h"

@interface AlertDispatcher : NSObject <UIAlertViewDelegate>
@property (nonatomic, strong) UIAlertView* alert;
@property (nonatomic) BOOL showing;
@end
@implementation AlertDispatcher

- (void) alert:(NSString*)title message:(NSString*)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.showing) {
            self.alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            self.showing = YES;
            [self.alert show];
        }
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.showing = NO;
}

@end

@implementation NSError (WhosAtGlue)

- (void) alert:(NSString*)title vc:(UIViewController*)vc
{
    static AlertDispatcher* dispatcher;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatcher = [[AlertDispatcher alloc] init];
    });
    
    BOOL show = YES;
    UIViewController* vcp = vc.parentViewController;
    if (vcp && [vcp isKindOfClass:[UINavigationController class]]) {
        show = [vc isEqual:[(UINavigationController*)vcp topViewController]];
    } else {
        id vcgp = vcp.parentViewController;
        if (vcgp && [vcgp isKindOfClass:[UINavigationController class]]) {
            show = [vcp isEqual:[(UINavigationController*)vcgp topViewController]];
        }
    }
    
    if (show) {
        [dispatcher alert:title message:self.localizedDescription];
    } else {
        NSLog(@"background error: %@", self);
    }
}

@end
