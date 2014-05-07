//
//  SettingsTableViewController.m
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

#import "SettingsTableViewController.h"
#import "KCSUser+WhosAtGlue.h"
#import "AppDelegate.h"
#import "M13Checkbox.h"
#import "CircleImageView.h"
#import "KinveyInfoTableViewController.h"
#import "BeaconModel.h"
#import "PushWrapper.h"

#import "NSError+WhosAtGlue.h"

#define kInfoCell @"infoCell"
#define kButtonCell @"buttonCell"
#define kCheckCell @"checkCell"
#define kPhotoCell @"photoCell"
#define kSwitchCell @"switchCell"

#define kCameraFlag 1 << UIImagePickerControllerSourceTypeCamera
#define kPhotoAlbumFlag 1 << UIImagePickerControllerSourceTypePhotoLibrary

typedef enum : NSUInteger {
    PICTURE,
    NAME,
    HEADLINE,
    EMAIL,
    PERSONAL_INFO_ROW_COUNT
} PERSONAL_INFO_ROWS;

typedef enum : NSUInteger {
    PERSONAL_INFO,
    INTERESTS,
    PRIVACY,
    LOGOUT,
    KINVEY_INFO,
    LEGAL,
    SECTION_COUNT
} Sections;

@interface SettingsTableViewController () <UITextFieldDelegate, UIActionSheetDelegate, CircleImageViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) NSDictionary* sectionTitles;
@property (nonatomic, strong) NSDictionary* rowCounts;
@property (nonatomic, strong) NSDictionary* rowIdentifiers;
@property (nonatomic, strong) NSDictionary* contents;
@property (nonatomic, strong) NSArray* interests;
@property (nonatomic, strong) NSMutableArray* selectedToLearns;
@property (nonatomic, strong) NSMutableArray* selectedToTalks;
@property (nonatomic) BOOL updated;
@property (nonatomic) NSUInteger sourceTypes;
@property (nonatomic) BOOL uploading;
@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"SETTINGS";
    
    self.interests = [[(AppDelegate*)[UIApplication sharedApplication].delegate eventModel] interests];
    self.selectedToTalks = [NSMutableArray arrayWithArray:[KCSUser activeUser].talkInterests];
    self.selectedToLearns = [NSMutableArray arrayWithArray:[KCSUser activeUser].learnInterests];

    
    self.sectionTitles = @{@(PERSONAL_INFO):@"PERSONAL INFO",      @(LOGOUT):@"LOGOUT",@(INTERESTS):@"INTERESTS",@(PRIVACY):@"PRIVACY"};
    self.rowCounts = @{@(PERSONAL_INFO):@(PERSONAL_INFO_ROW_COUNT),
                       @(LOGOUT):@(1),
                       @(INTERESTS):@(self.interests.count),
                       @(PRIVACY):@(1),
                       @(LEGAL):@1,
                       @(KINVEY_INFO):@1};
    self.rowIdentifiers = @{@(PERSONAL_INFO):@[kPhotoCell,kInfoCell,kInfoCell,kInfoCell],
                            @(LOGOUT):@[kButtonCell],
                            @(PRIVACY): kSwitchCell,
                            @(INTERESTS):kCheckCell,
                            @(LEGAL):kButtonCell,
                            @(KINVEY_INFO):kButtonCell};

    
    NSDictionary* infoConents = @{@(NAME)    :@{@"label":@"Full Name",@"placeholder":@"John Q. Public",         @"kt":@(UIKeyboardTypeDefault),     @"kc":@(UITextAutocapitalizationTypeWords)},
                                  @(HEADLINE):@{@"label":@"Headline", @"placeholder":@"Chief Mugwump at Kinvey",@"kt":@(UIKeyboardTypeDefault),     @"kc":@(UITextAutocapitalizationTypeSentences)},
                                  @(EMAIL)   :@{@"label":@"Email",    @"placeholder":@"john@kinvey.com",        @"kt":@(UIKeyboardTypeEmailAddress),@"kc":@(UITextAutocapitalizationTypeNone)}};
    NSDictionary* logoutContents = @{@(0):@{@"title":@"Logout"}};
    self.contents = @{@(PERSONAL_INFO):infoConents,
                      @(LOGOUT):logoutContents,
                      @(KINVEY_INFO):@{@0:@{@"title":@"About Kinvey"}},
                      @(LEGAL):@{@0:@{@"title":@"About this app"}},
                      @(PRIVACY):@{@0:@{@"title":@"Push Notifications"}}};
}


- (void)viewWillDisappear:(BOOL)animated
{
    [KCSUser activeUser].talkInterests = self.selectedToTalks;
    [KCSUser activeUser].learnInterests = self.selectedToLearns;
    
    if (self.updated) {
        [[KCSUser activeUser] saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            if (errorOrNil) {
                //do nothing - there's no plan for recovery
                NSLog(@"error saving user: %@", errorOrNil);
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:UserUpdated object:[KCSUser activeUser]];
            }
        }];
    }
}

#pragma mark - Table view data source

- (NSString*) infoValueAtIndexPath:(NSIndexPath *)indexPath
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

- (void) setValue:(NSString*)value atIndexPath:(NSIndexPath *)indexPath
{
    self.updated = YES;
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.rowCounts[@(section)] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellId = self.rowIdentifiers[@(indexPath.section)];
    if ([cellId isKindOfClass:[NSArray class]]) {
        cellId = [(NSArray*)cellId objectAtIndex:indexPath.row];
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    NSDictionary* info = self.contents[@(indexPath.section)][@(indexPath.row)];
    if ([cellId isEqualToString:kInfoCell]) {
        UILabel* leftLabel = (UILabel*)[cell.contentView viewWithTag:1];
        UITextField* rightTextField = (UITextField*)[cell.contentView viewWithTag:2];
        
        leftLabel.text = info[@"label"];
        rightTextField.placeholder = info[@"placeholder"];
        rightTextField.keyboardType = [info[@"kt"] intValue];
        rightTextField.autocapitalizationType = [info[@"kc"] intValue];
        rightTextField.returnKeyType = indexPath.row == self.contents.count - 1 ? UIReturnKeyDone : UIReturnKeyNext;
        
        NSString* value = [self infoValueAtIndexPath:indexPath];
        rightTextField.text = value;

    } else if ([cellId isEqualToString:kButtonCell]) {
        cell.textLabel.text = info[@"title"];
    } else if ([cellId isEqualToString:kCheckCell]) {
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
    } else if ([cellId isEqualToString:kPhotoCell]) {
        CircleImageView* imView = (CircleImageView*)[cell.contentView viewWithTag:1];
        imView.image = [KCSUser activeUser].picture;
        imView.delegate = self;
        UIActivityIndicatorView* activity = (UIActivityIndicatorView*)[cell.contentView viewWithTag:3];
        UILabel* cellLabel = (UILabel*)[cell.contentView viewWithTag:2];
        if (self.uploading) {
            [activity startAnimating];
            cellLabel.text = @"Uploading...";
        } else {
            [activity stopAnimating];
            cellLabel.text = @"Tap to change picture";
        }
    } else if ([cellId isEqualToString:kSwitchCell]) {
        UILabel* titleLabel = (UILabel*)[cell.contentView viewWithTag:1];
        UISwitch* aSwitch = (UISwitch*)[cell.contentView viewWithTag:2];
        
        titleLabel.text = info[@"title"];
        NSNumber* notifcationOn = [KCSUser activeUser].notificationsOn;
        aSwitch.on = [notifcationOn boolValue];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sectionTitles[@(section)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellId = self.rowIdentifiers[@(indexPath.section)];
    if ([cellId isKindOfClass:[NSArray class]]) {
        cellId = [(NSArray*)cellId objectAtIndex:indexPath.row];
    }

    return [cellId isEqualToString:kPhotoCell] ? 80. : 44.;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case PERSONAL_INFO: {
            if (indexPath.row == PICTURE) {
                [self circleImageViewTapped:nil];
            }
        }
            break;
        case LOGOUT:
            [[KCSUser activeUser] logout];
            [(AppDelegate*)[UIApplication sharedApplication].delegate login];
            break;
        case KINVEY_INFO:
        {
            UIStoryboard* board = [UIStoryboard storyboardWithName:@"KinveyInfo" bundle:nil];
            [self.navigationController pushViewController:[board instantiateViewControllerWithIdentifier:@"KinveyInfo"] animated:YES];
        }
            break;
        case LEGAL:
            [self performSegueWithIdentifier:@"showInfo" sender:nil];
            break;
        default:
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return section == INTERESTS ? self.labelView : nil;
}

#pragma mark - Checkbox

- (IBAction)checkboxed:(M13Checkbox*)sender
{
    self.updated = YES;
    
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

#pragma mark - Text Field

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSIndexPath* p = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:textField.center fromView:textField.superview]];
    NSString* orig = textField.text;
    NSString* new = [orig stringByReplacingCharactersInRange:range withString:string];

    [self setValue:new atIndexPath:p];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    NSIndexPath* p = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:textField.center fromView:textField.superview]];
    [self setValue:@"" atIndexPath:p];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSIndexPath* p = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:textField.center fromView:textField.superview]];
    [self setValue:textField.text atIndexPath:p];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    
    CGPoint p = [self.tableView convertPoint:textField.center fromView:textField.superview];
    NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:p];
    
    NSUInteger count = [self tableView:self.tableView numberOfRowsInSection:indexPath.section];
    
    if (indexPath.row == count - 1) {
        [textField resignFirstResponder];
    } else {
        [[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section]].contentView viewWithTag:2] becomeFirstResponder];
    }
    
    
    return YES;
}


#pragma mark - Image 
- (void)circleImageViewTapped:(CircleImageView *)imageView
{
    if (self.uploading) {
        return;
    }
    
    //check camera
    self.sourceTypes = 0;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.sourceTypes = self.sourceTypes | kCameraFlag;
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.sourceTypes = self.sourceTypes | kPhotoAlbumFlag;
    }
    
    UIActionSheet* sheet;
    
    if (self.sourceTypes & kCameraFlag && self.sourceTypes & kPhotoAlbumFlag) {
        sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take photo", @"Choose existing photo", nil];
    } else if (self.sourceTypes & kCameraFlag) {
        sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take photo", nil];
    } else if (self.sourceTypes & kPhotoAlbumFlag) {
        sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Choose existing photo", nil];
    }
    
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger button = buttonIndex - [actionSheet firstOtherButtonIndex];
    if (button < 0 || button == [actionSheet cancelButtonIndex]) {
        return;
    }
    
    if (self.sourceTypes & kCameraFlag && self.sourceTypes & kPhotoAlbumFlag) {
        switch (button) {
            case 0:
                [self takePhoto];
                break;
            case 1:
                [self useExisting];
            default:
                break;
        }
    } else if (self.sourceTypes & kCameraFlag) {
        [self takePhoto];
    } else if (self.sourceTypes & kPhotoAlbumFlag) {
        [self useExisting];
    }
}

- (void) takePhoto
{
    UIImagePickerController* imPicker = [[UIImagePickerController alloc] init];
    imPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imPicker.delegate = self;
    imPicker.cameraDevice = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ? UIImagePickerControllerCameraDeviceFront : UIImagePickerControllerCameraDeviceRear;
    imPicker.allowsEditing = YES;
    imPicker.showsCameraControls = YES;
    
    CGRect f = imPicker.view.bounds;
    UIGraphicsBeginImageContext(f.size);
    CGRect square = CGRectMake(0, (f.size.height - f.size.width) / 2. - 36, f.size.width, f.size.width);
    [[UIColor yellowColor] set];
    UIRectFrameUsingBlendMode(square, kCGBlendModeNormal);

    [[UIColor colorWithWhite:0 alpha:.5] set];
    CGRect topBar = CGRectMake(0, CGRectGetMinY(square) - 20, f.size.width, 20);
    UIRectFillUsingBlendMode(topBar, kCGBlendModeNormal);
    CGRect bottomBar = CGRectMake(0, CGRectGetMaxY(square), f.size.width, 90);
    UIRectFillUsingBlendMode(bottomBar, kCGBlendModeNormal);
    
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *overlayIV = [[UIImageView alloc] initWithFrame:f];
    overlayIV.image = overlayImage;
    
    imPicker.cameraOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    [imPicker.cameraOverlayView addSubview:overlayIV];
    
    [self presentViewController:imPicker animated:YES completion:nil];
}

- (void) useExisting
{
    UIImagePickerController* imPicker = [[UIImagePickerController alloc] init];
    imPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imPicker.delegate = self;
    [self presentViewController:imPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* im = info[UIImagePickerControllerEditedImage];
    if (!im) {
        im = info[UIImagePickerControllerOriginalImage];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    if (im) {
        CGFloat f = 122.0 * 2.0;
        UIGraphicsBeginImageContext(CGSizeMake(f, f));
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        CGSize imSize = im.size;
        
        CGFloat x,y,w,h,ar;
        if (imSize.width > imSize.height) {
            ar = f / imSize.height;
            w = imSize.width * ar;
            h = imSize.height * ar;
            x = - (w-h)/ 2.0;
            y = 0.0;
        } else {
            ar = f / imSize.width;
            w = imSize.width * ar;
            h = imSize.height * ar;
            x = 0.0;
            y = - (h-w)/2.0;
        }
        
        [im drawInRect:CGRectIntegral(CGRectMake(x, y, w, h))];
        CGContextRestoreGState(context);
        UIImage *newIm = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData* imData = UIImageJPEGRepresentation(newIm, .75);
        [[KCSUser activeUser] setPicture:imData];
        self.uploading = YES;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PICTURE inSection:PERSONAL_INFO]] withRowAnimation:UITableViewRowAnimationFade];
        [KCSFileStore uploadData:imData options:@{KCSFilePublic : @YES, KCSEntityKeyId : [KCSUser activeUser].userId} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
            if (error) {
                [error alert:@"Unable to upload a new photo. Try again later." vc:self];
            } else {
                NSString* newUrl = uploadInfo.downloadURL;
                if (newUrl) {
                    [[KCSUser activeUser] setPictureURL:newUrl];
                    self.updated = YES;
                }
            }
            self.uploading = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:PICTURE inSection:PERSONAL_INFO]] withRowAnimation:UITableViewRowAnimationFade];
            });
        } progressBlock:nil];
    }
}

#pragma mark - Switch
- (IBAction)switched:(UISwitch*)sender
{
    //will need to better encapsulate when multiple switches are introduced
    [KCSUser activeUser].notificationsOn = @(sender.on);
    [KCSUser activeUser].dirty = YES;
    
    if (sender.on) {
        [PushWrapper registerToken];
    } else {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
}

@end
