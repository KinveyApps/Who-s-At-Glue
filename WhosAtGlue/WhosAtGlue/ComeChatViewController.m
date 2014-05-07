//
//  ComeChatViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/1/14.
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

#import "ComeChatViewController.h"

@import MessageUI;

@interface ComeChatViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation ComeChatViewController

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
    // Do any additional setup after loading the view.
    CGRect f = self.lastTime.frame;
    self.scrollView.contentSize = CGSizeMake(CGRectGetMaxX(f), CGRectGetMaxY(f));
    self.chatLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.chatLabel addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIScrollView*) scrollView
{
    return (UIScrollView*)self.view;
}

- (void) tapped:(UITapGestureRecognizer*)tap
{
    if (tap.state == UIGestureRecognizerStateRecognized) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        
        [picker setToRecipients:@[@"Kinvey<sales@kinvey.com>"]];
        [picker setSubject:@"I want to learn about Kinvey."];
        
        // Fill out the email body text
//        NSString *emailBody = [NSString stringWithFormat:@"Who's At Glue? is an beacon-enabled conference meet-up app powered by Kinvey.\n\n Check out the iOS Source code for the app at:\n\n https://github.com/KinveyApps/Who-s-At-Glue"];
//        [picker setMessageBody:emailBody isHTML:NO];
//        
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
//
//- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
//{
//    return self.imageView;
//}

@end
