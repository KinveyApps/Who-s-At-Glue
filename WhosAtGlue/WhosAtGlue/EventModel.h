//
//  EventModel.h
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

#import <Foundation/Foundation.h>

KCS_CONSTANT MessagesUpdatedNotification;
KCS_CONSTANT ConferenceStartingNotification;

@interface EventModel : NSObject
@property (nonatomic, strong) NSMutableArray* unreadMessages;

- (NSArray*) interests;
- (NSArray*) messagesForUser:(NSString*)userId;
- (NSArray*) unreadMessagesForUser:(NSString*)userId;

- (void) markMessageAsRead:(NSMutableDictionary*)message;

- (double) boothPopupAccuracy;
- (NSString*) portalURL;

- (NSDate*) startDate;
- (NSDate*) endDate;
- (NSInteger) timeYet;

- (void) atSetup:(void(^)())callback;

@end
