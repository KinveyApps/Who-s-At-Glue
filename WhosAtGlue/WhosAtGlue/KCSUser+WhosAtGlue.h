//
//  KCSUser+WhosAtGlue.h
//  WhosAtGlue
//
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

#import <KinveyKit/KinveyKit.h>

#define kFormattedName @"formatted_name"
#define kHeadline @"headline"
#define kTalkInterests @"talkInterests"
#define kLearnInterests @"learnInterests"
#define kEvent @"event"
#define kSetup @"setup"
#define kNotificationsOn @"notificationsOn"

#define UserPictureNotification @"userpicturenote"

@interface KCSUser (WhosAtGlue)
@property (nonatomic, strong) NSString* formattedName;
@property (nonatomic, strong) NSString* headline;
@property (nonatomic, strong) NSArray* learnInterests;
@property (nonatomic, strong) NSArray* talkInterests;
@property (nonatomic, strong) NSString* event;
@property (nonatomic, readonly) NSArray* messages;
@property (nonatomic) BOOL setup;
@property (nonatomic, strong) NSNumber* notificationsOn;

- (UIImage*) picture;
+ (UIImage*) picture:(NSDictionary*)userDict;
- (void)setPicture:(NSData*)pictureData;
- (void) setPictureURL:(id)url;
- (NSDictionary*) dict;

@end
