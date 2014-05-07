//
//  UserProfileViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/4/14.
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

#import "UserProfileViewController.h"

#import "RDRStickyKeyboardView.h"

#import "CircleImageView.h"
#import "KWLineView.h"
#import "NSError+WhosAtGlue.h"
#import "ProgressHUD.h"

#import "AppDelegate.h"
#import "KCSUser+WhosAtGlue.h"
#import "BeaconModel.h"
#import "PushWrapper.h"

#define kImageSize 122
#define kHeader 27
#define kLine 42
#define kName 20
#define kHeadlineHeight 38
#define kSizePlus20 -1
#define kMargin 20

@interface PictureCell : UITableViewCell
@property (nonatomic, strong) CircleImageView* pictureView;
@end

@implementation PictureCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.pictureView = [[CircleImageView alloc] initWithFrame:CGRectMake(0, 0, kImageSize, kImageSize)];
        self.pictureView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        //        [s]
        [self.contentView addSubview:self.pictureView];

        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    CGRect bounds = self.contentView.bounds;
    self.pictureView.center = CGPointMake(bounds.size.width / 2., kImageSize / 2.);
}

@end


@interface LineCell : UITableViewCell
@property (nonatomic, strong) KWLineView* lineView;
@end

@implementation LineCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.lineView = [[KWLineView alloc] initWithFrame:CGRectMake(0, 0, 110, 10)];
        self.lineView.lineDirection = KWLineViewDirectionHorizontal;
        self.lineView.strokeWidth = 2.;
        self.lineView.strokeColor = [UIColor reddishColor];
        [self.contentView addSubview:self.lineView];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGRect b = self.contentView.bounds;
    b = CGRectInset(b, 20, 20);
    self.lineView.frame = b;
}
@end

@interface LabelTableViewCell : UITableViewCell

@end

@implementation LabelTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSeparatorStyleNone;
        self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        self.textLabel.textColor = [UIColor orangishColor];
    }
    return self;
}

@end

@interface HeadlineTableViewCell : LabelTableViewCell

@end

@implementation HeadlineTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        self.textLabel.textColor = [UIColor darkGrayColor];
        self.textLabel.numberOfLines = 0;
        self.selectionStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

@end

@interface MessageLabel : UILabel
@property (nonatomic, strong) UIColor* borderColor;
@property (nonatomic) BOOL unread;
@end

@implementation MessageLabel

- (void) drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:CGRectInset(rect, 4, 0)];
}


@end

@interface MessageCell : UITableViewCell
@property (nonatomic, strong) MessageLabel* messageLabel;
@property (nonatomic) BOOL me;
@end

@implementation MessageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _messageLabel = [[MessageLabel alloc] initWithFrame:self.contentView.bounds];
        _messageLabel.textColor = [UIColor darkTextColor];
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _messageLabel.numberOfLines = 0;
        _messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.autoresizingMask = UIViewAutoresizingNone;
        _messageLabel.clipsToBounds = YES;
        _messageLabel.layer.borderWidth = 2;
        _messageLabel.layer.cornerRadius = 4;
        [self.contentView addSubview:_messageLabel];
        
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize s = [self.messageLabel sizeThatFits:CGSizeMake(self.frame.size.width - 16., 10000)];
    CGRect f = self.bounds;
    if (_me) {
        f.origin.x = f.size.width - s.width - 12.;
        f.size.width = s.width + 8;
    } else {
        f.origin.x = 4;
        f.size.width = s.width + 8;
    }
    f.origin.y = 4;
    f.size.height -= 8;
    self.messageLabel.frame = f;
}

- (void) setMe:(BOOL)me
{
    _me = me;
    
    self.messageLabel.borderColor = me ? [UIColor blueColor] : [UIColor grayColor];
    self.messageLabel.layer.borderColor = me ? [UIColor blueColor].CGColor : [UIColor grayColor].CGColor;

}

- (void) setUnread:(BOOL)unread
{
    self.messageLabel.backgroundColor = unread ? [UIColor helperFontColor] : [UIColor clearColor];
}
@end

@interface UserProfileViewController ()  <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) RDRStickyKeyboardView *contentWrapper;

@property (nonatomic, strong) NSDictionary* contents;
@property (nonatomic, strong) NSMutableArray* userMessages;


@property (nonatomic, strong) KCSCachedStore* messageStore;
@end

@implementation UserProfileViewController

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    [self _setupSubviews];
    
    self.contents = @{@0:@{@"id":@"PictureCell", @"height":@(kImageSize)},
                      @1:@{@"id":@"LineCell",    @"height":@(kLine)},
                      @2:@{@"id":@"LabelCell",   @"height":@(kName),      @"text" : (NSString*)^(){ return  self.user[@"formatted_name"];}},
                      @3:@{@"id":@"Headline",   @"height":@(kHeadlineHeight),   @"text" : (NSString*)^(){ return  self.user[@"headline"];}},
                      @4:@{@"id":@"Headline",   @"height":@(kSizePlus20), @"text" : (NSString*)^(){ return  [NSString stringWithFormat:@"INTERESTS: %@", self.user[@"talkInterests"] ? [self.user[@"talkInterests"] componentsJoinedByString:@", "] : @""];}}
                      };
    
    KCSCollection* messagesCollection = [KCSCollection collectionFromString:@"messages" ofClass:[NSMutableDictionary class]];
    self.messageStore = [KCSCachedStore storeWithCollection:messagesCollection options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst), KCSStoreKeyOfflineUpdateEnabled : @YES}];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString* action = @"Meet";
    if (self.userMessages.count > 0) {
        NSDictionary* msg = self.userMessages.lastObject;
        NSString* tgtUser = msg[@"targetUser"];
        BOOL theySent = [tgtUser isEqualToString:[KCSUser activeUser].userId];
        action = theySent ? @"Reply to" : @"Message";
    }
    NSString* name = self.user[KCSUserAttributeGivenname] ? self.user[KCSUserAttributeGivenname] : self.user[@"formatted_name"];
    NSString* meetTitle = [NSString stringWithFormat:@"%@ %@",action, name];
    self.contentWrapper.placeholder = meetTitle;

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated) name:UserUpdated object:nil];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UserUpdated object:nil];
    for (NSMutableDictionary* d in self.userMessages) {
        if (![d[@"read"] boolValue] && [d[@"targetUser"] isEqualToString:[KCSUser activeUser].userId]) {
            [[(AppDelegate*)[UIApplication sharedApplication].delegate eventModel] markMessageAsRead:d];
        }
    }
    if (self.userMessages) {
        self.user[@"messages"] = self.userMessages;
    }
}


- (void) userUpdated
{
    NSArray* a = [KCSUser activeUser].messages;
    NSArray* newMessages = [a filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"_acl.creator LIKE %@", self.user[KCSEntityKeyId]]];
    if ([newMessages count] > 0) {
        [self.tableView beginUpdates];
        NSMutableArray* ipaths = [NSMutableArray array];
        for (NSDictionary* m in newMessages) {
            if (![self.userMessages containsObject:m]) {
                [self.userMessages addObject:m];
                [ipaths addObject:[NSIndexPath indexPathForRow:self.userMessages.count-1 inSection:1]];
            }
        }
        if (ipaths.count > 0) {
            [self.tableView insertRowsAtIndexPaths:ipaths withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
        if (ipaths.count > 0) {
            [self.tableView scrollToRowAtIndexPath:[ipaths lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

#pragma mark - Private

- (void)_setupSubviews
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    // Setup tableview
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[PictureCell class] forCellReuseIdentifier:@"PictureCell"];
    [self.tableView registerClass:[LineCell class] forCellReuseIdentifier:@"LineCell"];
    [self.tableView registerClass:[LabelTableViewCell class] forCellReuseIdentifier:@"LabelCell"];
    [self.tableView registerClass:[HeadlineTableViewCell class] forCellReuseIdentifier:@"Headline"];
    [self.tableView registerClass:[MessageCell class] forCellReuseIdentifier:@"Cell"];
    
    UIView* hv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 27, 27)];
    self.tableView.tableHeaderView = hv;
    
    // Setup wrapper
    self.contentWrapper = [[RDRStickyKeyboardView alloc] initWithScrollView:self.tableView];
    self.contentWrapper.frame = self.view.bounds;
    self.contentWrapper.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.contentWrapper];
    
    [self.contentWrapper.inputView.rightButton addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
    NSString* cellId = @"Cell";
    NSDictionary* content = self.contents[@(indexPath.row)];
    if (content) {
        cellId = content[@"id"];
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    
    if (content) {
        if ([cell isKindOfClass:[PictureCell class]]) {
            PictureCell* pc = (PictureCell*) cell;
            pc.pictureView.image = [KCSUser picture:self.user];
        }
        if ([cell isKindOfClass:[LabelTableViewCell class]]) {
            NSString* (^textBlock)() = content[@"text"];
            cell.textLabel.text = textBlock();
        }
    } else {
        cell.backgroundColor = [UIColor redColor];
        cell.contentView.backgroundColor = [UIColor redColor];
    }
    
    return cell;
    } else {
        MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        NSDictionary* message = self.userMessages[indexPath.row];
        cell.messageLabel.text = message[@"message"];
        NSString* tgtUser = message[@"targetUser"];

        BOOL theySent = [tgtUser isEqualToString:[KCSUser activeUser].userId];
        [cell setMe:!theySent];

        BOOL unread = theySent && ![message[@"read"] boolValue];
        cell.unread = unread;
        
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 5;
    } else {
        return self.userMessages.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat h = 44.;
    if (indexPath.section == 0) {
        NSDictionary* content = self.contents[@(indexPath.row)];
        h = content ? [content[@"height"] floatValue] : h;
        if (h == -1) {
            NSString* (^textBlock)() = content[@"text"];
            NSString* t = textBlock ? textBlock() : @"";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            CGSize s = [t sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] constrainedToSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height) lineBreakMode:NSLineBreakByTruncatingTail];
#pragma clang diagnostic pop
            h = s.height+20.;
        }
    } else if (indexPath.section == 1) {
        NSDictionary* message = self.userMessages[indexPath.row];
        NSString* messageText = message[@"message"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize s = [messageText sizeWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] constrainedToSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height) lineBreakMode:NSLineBreakByTruncatingTail];
#pragma clang diagnostic pop

        return h = s.height+16.;
    }
    return h;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section ? 32 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return section ? [[UIView alloc] init]: nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 1;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        [ProgressHUD show:@"Deleting"];
        NSDictionary* message = self.userMessages[indexPath.row];
        [self.messageStore removeObject:message[KCSEntityKeyId] withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ProgressHUD dismiss];
                if (errorOrNil) {
                    [errorOrNil alert:@"Unable to delete message." vc:self];
                } else {
                    [self.userMessages removeObject:message];
                    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            });
        } withProgressBlock:nil];
    }
}

#pragma mark - messaging

- (void)setUser:(NSMutableDictionary*) user
{
    _user = user;
    self.userMessages = [user[@"messages"] mutableCopy];
}

- (void) send:(UIControl*)sender
{
    UITextView* textView = self.contentWrapper.inputView.textView;
    NSString* text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text) {
        NSString* userId = self.user[KCSEntityKeyId];
        NSMutableDictionary* message = [@{@"read":@NO,
                                  @"event": self.user[@"event"],
                                  @"targetUser": userId,
                                  @"_acl":@{@"w":@[userId]},
                                  @"message":text} mutableCopy];
        
        [self.contentWrapper setEnabled:NO];
        [self.messageStore saveObject:message withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorOrNil) {
                    [errorOrNil alert:@"Could not send message" vc:self];
                } else {
                    [self.contentWrapper clearText];
                }
                [self.contentWrapper setEnabled:YES];
            });
        } withProgressBlock:nil];
        if (!self.userMessages) {
            self.userMessages = [NSMutableArray array];
        }
        [self.userMessages addObject:message];
        [self.tableView reloadData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [PushWrapper register];
        });
    }
    
    [self.contentWrapper.inputView.textView resignFirstResponder];
    // For dummyInputView.textView
    [self.view endEditing:YES];
    

}
@end
