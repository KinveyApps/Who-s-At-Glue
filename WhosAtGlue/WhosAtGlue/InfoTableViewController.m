//
//  InfoTableViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/13/14.
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

#import "InfoTableViewController.h"
#import "LicenseTableViewController.h"

@import MessageUI;

@interface InfoTableViewController () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) NSArray* rows;
@end

@implementation InfoTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.rows = @[@"Who's at Glue?",
                  [NSString stringWithFormat:@"Version %@", [[NSBundle mainBundle] infoDictionary][(id)kCFBundleVersionKey]]
                  ];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UITableViewCell* c = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    c.detailTextLabel.text = [NSString stringWithFormat:@"Version %@", [[NSBundle mainBundle] infoDictionary][(id)kCFBundleVersionKey]];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LicenseTableViewController class]]) {
        NSArray* path;
        if ([segue.identifier isEqualToString:@"license"]) {
            path = @[[[NSBundle mainBundle] pathForResource:@"Pods-WhosAtGlue-acknowledgements" ofType:@"markdown"],[[NSBundle mainBundle] pathForResource:@"ExtraLicenses" ofType:@"txt"] ];
        } else if ([segue.identifier isEqualToString:@"privacy"]) {
            path = @[[[NSBundle mainBundle] pathForResource:@"PrivacyPolicy" ofType:@"txt"]];
        }
        [(LicenseTableViewController*)segue.destinationViewController setPaths:path];
    }
}

#pragma mark - Table View

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 1:
            [self emailCode];
            break;
            
        default:
            break;
    }
}

- (void) emailCode
{
    if ([MFMailComposeViewController canSendMail]) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Email source code link" message:@"Send this app's source code to check out later?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send email", nil];
        [alert show];        
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView firstOtherButtonIndex]) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        
        [picker setSubject:@"'Who's At Glue?' source code."];
        
        // Fill out the email body text
        NSString *emailBody = [NSString stringWithFormat:@"Who's At Glue? is an beacon-enabled conference meet-up app powered by Kinvey.\n\n Check out the iOS Source code for the app at:\n\n https://github.com/KinveyApps/Who-s-At-Glue"];
        [picker setMessageBody:emailBody isHTML:NO];
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString* text;
    switch (result)
    {
        case MFMailComposeResultCancelled:
            text = @"Result: Mail sending canceled";
            break;
        case MFMailComposeResultSaved:
            text = @"Result: Mail saved";
            break;
        case MFMailComposeResultSent:
            text = @"Result: Mail sent";
            break;
        case MFMailComposeResultFailed:
            text = @"Result: Mail sending failed";
            break;
        default:
            text = @"Result: Mail not sent";
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
