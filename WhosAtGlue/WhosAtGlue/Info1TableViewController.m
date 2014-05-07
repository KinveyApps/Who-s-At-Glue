//
//  Info1TableViewController.m
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

#import "Info1TableViewController.h"
#import "KCSUser+WhosAtGlue.h"

typedef enum : NSUInteger {
    NAME,
    HEADLINE,
    EMAIL
} ROWS;

@interface Info1TableViewController ()
@property (nonatomic, strong) NSDictionary* contents;
@end

@implementation Info1TableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor backgroundColor];

    

    self.contents = @{@(NAME)    :@{@"label":@"Full Name",@"placeholder":@"John Q. Public",         @"kt":@(UIKeyboardTypeDefault),     @"kc":@(UITextAutocapitalizationTypeWords)},
                      @(HEADLINE):@{@"label":@"Headline", @"placeholder":@"Chief Mugwump at Kinvey",@"kt":@(UIKeyboardTypeDefault),     @"kc":@(UITextAutocapitalizationTypeSentences)},
                      @(EMAIL)   :@{@"label":@"Email",    @"placeholder":@"john@kinvey.com",        @"kt":@(UIKeyboardTypeEmailAddress),@"kc":@(UITextAutocapitalizationTypeNone)}};

    UIBarButtonItem* back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = back;

    [self validate];
    
}

- (IBAction)skip:(id)sender
{
    [self performSegueWithIdentifier:@"interests" sender:sender];
}

#pragma mark - Data

- (NSString*) valueAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* value = @"";
    switch (indexPath.row) {
        case NAME: {
            NSString* name = [[KCSUser activeUser] formattedName];
            if (name) {
                value = name;
            }
        }
            
            break;
        case HEADLINE: {
            NSString* headline = [[KCSUser activeUser] headline];
            if (headline) {
                value = headline;
            }
        }
            break;
        case EMAIL: {
            NSString* email = [KCSUser activeUser].email;
            if (email) {
                value = email;
            }
        }
            break;
        default:
            break;
    }
    return value;
}

- (void) setValue:(id)value atIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case NAME:
            [KCSUser activeUser].formattedName = value;
            break;
        case HEADLINE:
            [KCSUser activeUser].headline = value;
            break;
        case EMAIL:
            [KCSUser activeUser].email = value;
            break;
        default:
            break;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contents.count;
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
    rightTextField.returnKeyType = indexPath.row == self.contents.count - 1 ? UIReturnKeyDone : UIReturnKeyNext;
    
    NSString* value = [self valueAtIndexPath:indexPath];
    rightTextField.text = value;
    return cell;
}

#pragma mark - Text Field

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    CGPoint p = [self.tableView convertPoint:textField.center fromView:textField.superview];
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:p];

    NSString* v = [self valueAtIndexPath:indexPath];
    NSString* newV = [v stringByReplacingCharactersInRange:range withString:string];
    [self setValue:newV atIndexPath:indexPath];
    
    [self validate];
    return YES;
}

- (void) validate
{
    BOOL isNext = [KCSUser activeUser] && ([[KCSUser activeUser] formattedName] || [[KCSUser activeUser] headline] || [KCSUser activeUser].email);
    if (isNext) {
        self.navigationItem.rightBarButtonItem.title = @"Next";
    }
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    CGPoint p = [self.tableView convertPoint:textField.center fromView:textField];
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:p];
    indexPath.row == self.contents.count - 1 ? [textField resignFirstResponder] : [[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section]].contentView viewWithTag:2] becomeFirstResponder];

    return YES;
}

@end
