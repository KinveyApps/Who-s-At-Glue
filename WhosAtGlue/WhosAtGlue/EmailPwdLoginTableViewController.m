//
//  EmailPwdLoginTableViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/26/14.
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


#import "EmailPwdLoginTableViewController.h"

#import "KCSUser+WhosAtGlue.h"

#import "NSError+WhosAtGlue.h"
#import "ProgressHUD.h"

@interface EmailPwdLoginTableViewController () <UITextFieldDelegate>
@property (nonatomic, strong) NSDictionary* contents;
@property (nonatomic, strong) NSMutableDictionary* values;
@property (nonatomic) BOOL working;
@end

@implementation EmailPwdLoginTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor backgroundColor];
    UIButton* backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    [backButton addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton setImage:[UIImage imageNamed:@"leftChevron"] forState:UIControlStateNormal];
    [backButton sizeToFit];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    self.navigationItem.leftBarButtonItem = backItem;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    NSString* title = self.createAccount ? @"SIGN UP" : @"LOG IN";
    self.titleLabel.text = title;
    self.title = title;
    self.navigationItem.rightBarButtonItem.title = self.createAccount ? @"Sign up" : @"Login";
    
    self.contents = @{@(0)    :@{@"label":@"Email",@"placeholder":@"wayne@batcave.com",@"kt":@(UIKeyboardTypeEmailAddress),     @"kc":@(UITextAutocapitalizationTypeNone)},
                      @(1):@{@"label":@"Password",@"placeholder":@"password",@"kt":@(UIKeyboardTypeDefault),     @"kc":@(UITextAutocapitalizationTypeNone),@"secure":@YES},
                      @(2):@{@"label":@"Repeat Password",@"placeholder":@"password",@"kt":@(UIKeyboardTypeDefault), @"kc":@(UITextAutocapitalizationTypeNone),@"secure":@YES}};
    self.values = [NSMutableDictionary dictionaryWithDictionary:@{@0:@"",@1:@"",@2:@""}];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.forgotPwdbutton.hidden = self.createAccount;
    if ([KCSUser activeUser]) {
        [self dismissViewControllerAnimated:YES completion:NO];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.createAccount ? 3 : 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellEditingStyleNone;
    UILabel* leftLabel = (UILabel*)[cell.contentView viewWithTag:1];
    UITextField* rightTextField = (UITextField*)[cell.contentView viewWithTag:2];
    
    NSDictionary* info = self.contents[@(indexPath.row)];
    
    leftLabel.text = info[@"label"];
    rightTextField.placeholder = info[@"placeholder"];
    rightTextField.keyboardType = [info[@"kt"] intValue];
    rightTextField.autocapitalizationType = [info[@"kc"] intValue];
    rightTextField.secureTextEntry = [info[@"secure"] boolValue];
    rightTextField.returnKeyType = indexPath.row == self.contents.count - 1 ? UIReturnKeyGo : UIReturnKeyNext;

    return cell;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSIndexPath* p = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:textField.center fromView:textField.superview]];
    NSString* orig = textField.text;
    NSString* new = [orig stringByReplacingCharactersInRange:range withString:string];
    self.values[@(p.row)] = new;
    [self updateButton];

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    NSIndexPath* p = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:textField.center fromView:textField.superview]];
    self.values[@(p.row)] = @"";
    [self updateButton];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSIndexPath* p = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:textField.center fromView:textField.superview]];
    self.values[@(p.row)] = textField.text;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self updateButton];
    
    CGPoint p = [self.tableView convertPoint:textField.center fromView:textField.superview];
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    self.values[@(indexPath.row)] = textField.text;
    
    NSUInteger count = [self tableView:self.tableView numberOfRowsInSection:0];
    
    if (indexPath.row == count - 1) {
        [textField resignFirstResponder];
        [self login:nil];
    } else {
        [[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section]].contentView viewWithTag:2] becomeFirstResponder];
    }
    
    
    return YES;
}

- (void) updateButton
{
    self.navigationItem.rightBarButtonItem.enabled = [self valid];
    if (self.createAccount && [self.values[@1] length] > 0 && [self.values[@2] length] > 1) {
        BOOL passwordsMatch = [self.values[@1] isEqualToString:self.values[@2]];
        self.pwdMustMatchLabel.hidden = passwordsMatch;
    } else {
        self.pwdMustMatchLabel.hidden = YES;
    }
}

- (BOOL) valid
{
    BOOL valid = [self.values[@0] length] > 0 && [self.values[@1] length] > 0;
    if (self.createAccount) {
        valid = valid && [self.values[@1] isEqualToString:self.values[@2]];
    }
    return valid;
}

- (void) setWorking:(BOOL)working
{
    _working = working;
    [self updateView];
}

- (void) updateView
{
    self.navigationItem.rightBarButtonItem.enabled = !self.working;
    if (self.working) {
        [ProgressHUD show:@"Please wait..."];
    } else {
        [ProgressHUD dismiss];
    }
}

- (IBAction)login:(id)sender
{
    if (![self valid] || self.working) {
        return;
    }
    [self.view endEditing:YES];
    
    self.working = YES;
    if (self.createAccount) {
        [KCSUser userWithUsername:self.values[@0] password:self.values[@1] fieldsAndValues:@{KCSUserAttributeEmail : self.values[@0]} withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
            self.working = NO;
            if (!errorOrNil) {
                
                [self showSetup];
            } else {
                [errorOrNil alert:@"Unable to create account" vc:self];
            }
        }];
    } else {
        [KCSUser loginWithUsername:self.values[@0] password:self.values[@1] withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
            self.working = NO;
            if (!errorOrNil) {
                [self showSetup];
            } else {
                [errorOrNil alert:@"Unable to log in" vc:self];
            }
        }];
    }
}

- (void) showSetup
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KCSUser activeUser].setup) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            UIStoryboard* sb = [UIStoryboard storyboardWithName:@"UserProfile" bundle:nil];
            UIViewController* restOfLogin = [sb instantiateInitialViewController];
            [self presentViewController:restOfLogin animated:YES completion:nil];
        }
    });
}

- (void) goback
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
