//
//  PasswordResetViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/3/14.
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

#import "PasswordResetViewController.h"

#import "NSError+WhosAtGlue.h"
#import "ProgressHUD.h"

@interface PasswordResetViewController ()
@property (nonatomic) BOOL working;
@end

@implementation PasswordResetViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)sendEmail:(id)sender
{
    NSString* email = self.emailField.text;
    
    if (email.length > 0) {
        self.working = YES;
        [KCSUser sendPasswordResetForUser:email withCompletionBlock:^(BOOL emailSent, NSError *errorOrNil) {
            self.working = NO;
            if (errorOrNil) {
                [errorOrNil alert:@"Unable to send email." vc:self];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"Email sent" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    [self.navigationController popViewControllerAnimated:YES];
                });
            }
        }];
    }
}

- (void) setWorking:(BOOL)working
{
    _working = working;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateView];
    });
}

- (void) updateView
{
    self.sendButton.enabled = !self.working;
    if (self.working) {
        [ProgressHUD show:@"Please wait..."];
    } else {
        [ProgressHUD dismiss];
    }
}

@end
