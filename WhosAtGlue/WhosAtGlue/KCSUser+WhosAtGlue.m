//
//  KCSUser+WhosAtGlue.m
//  WhosAtGlue
//
//  Created by Michael Katz on 3/19/14.
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
#import "KCSUser+WhosAtGlue.h"

@interface NSDate (ISO8601)

- (NSString *)stringWithISO8601Encoding;
+ (NSDate *)dateFromISO8601EncodedString: (NSString *)string;

@end


@interface WhosAtGlueFM : NSFileManager <NSFileManagerDelegate>

@end

@implementation WhosAtGlueFM

- (id)init
{
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    return self;
}

- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
    return YES;
}

@end

@implementation KCSUser (WhosAtGlue)
@dynamic formattedName;
@dynamic headline;
@dynamic learnInterests;
@dynamic talkInterests;
@dynamic event;
@dynamic messages;
@dynamic setup;
@dynamic notificationsOn;

- (NSString *)formattedName
{
    NSString* name = [self getValueForAttribute:kFormattedName];
    if (!name) {
        NSString* fname = self.givenName;
        NSString* lname = self.surname;
        if (fname && lname) {
            name = [NSString stringWithFormat:@"%@ %@", fname, lname];
        } else {
            if (fname) {
                name = fname;
            } else if (lname) {
                name = lname;
            }
        }
    }
    return name;
}

- (void)setFormattedName:(NSString *)formattedName
{
    [self setValue:formattedName forAttribute:kFormattedName];
}

- (NSString *)headline
{
    return [self getValueForAttribute:kHeadline];
}

- (void)setHeadline:(NSString *)headline
{
    [self setValue:headline forAttribute:kHeadline];
}

- (NSArray *)talkInterests
{
    return [self getValueForAttribute:kTalkInterests];
}

- (void)setTalkInterests:(NSArray *)talkInterests
{
    [self setValue:talkInterests forAttribute:kTalkInterests];
}

- (NSArray *)learnInterests
{
    return [self getValueForAttribute:kLearnInterests];
}

- (void)setLearnInterests:(NSArray *)learnInterests
{
    [self setValue:learnInterests forAttribute:kLearnInterests];
}

+ (UIImage*) picture:(NSDictionary*)userDict
{
    UIImage* image = nil;
    
    NSString* userId = userDict[KCSEntityKeyId];
    NSDate* remoteLMT = userDict[@"pictureLMT"];
    if ([remoteLMT isKindOfClass:[NSString class]]) {
        remoteLMT = [NSDate dateFromISO8601EncodedString:(NSString*)remoteLMT];
    }
    
    NSString* file = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:userId];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        NSError* error = nil;
        NSDictionary* d = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:&error];
        if (!error) {
            NSDate* localLMT = d[NSFileModificationDate];
            if (!remoteLMT || [localLMT compare:remoteLMT] == NSOrderedDescending) {
                UIImage* fileImage = [UIImage imageWithContentsOfFile:file];
                if (fileImage) {
                    image = fileImage;
                }
            }
        }
    }
    
    if (!image) {
        NSString* pictureURL = userDict[@"pictureUrl"];
        if (pictureURL) {
            NSURLSession* urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            [[urlSession downloadTaskWithURL:[NSURL URLWithString:pictureURL] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (!error && location) {
                    UIImage* fileImage = [UIImage imageWithContentsOfFile:[location path]];
                    if (fileImage) {
                        NSFileManager* fm = [[WhosAtGlueFM alloc] init];
                        [fm moveItemAtPath:[location path] toPath:file error:NULL];

                        [[NSNotificationCenter defaultCenter] postNotificationName:UserPictureNotification object:userId];
                    }
                } else {
                    NSLog(@"error downloading image:%@", error);
                }
            }] resume];
        }
    }
    
    return image ? image : [UIImage imageNamed:@"userIcon"];
}

- (UIImage *)picture
{
    UIImage* image = nil;
    
    NSString* file = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:self.userId];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        UIImage* fileImage = [UIImage imageWithContentsOfFile:file];
        if (fileImage) {
            image = fileImage;
        }
    }
    
    if (!image) {
        NSString* pictureURL = [self getValueForAttribute:@"pictureUrl"];
        if (pictureURL) {
            NSURLSession* urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            [[urlSession downloadTaskWithURL:[NSURL URLWithString:pictureURL] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (!error && location) {
                    UIImage* fileImage = [UIImage imageWithContentsOfFile:[location path]];
                    if (fileImage) {
                        [self willChangeValueForKey:@"picture"];
                        [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:file error:NULL];
                        [self didChangeValueForKey:@"picture"];
                    }
                } else {
                    NSLog(@"error downloading image:%@", error);
                }
            }] resume];
        }
    }
    
    return image ? image : [UIImage imageNamed:@"userIcon"];
}

- (void)setPicture:(NSData*)pictureData
{
    NSString* file = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:self.userId];
    [pictureData writeToFile:file atomically:YES];
}

- (void)setPictureURL:(id)url
{
    [self setValue:url forAttribute:@"pictureUrl"];
    [self setValue:[NSDate date] forAttribute:@"pictureLMT"];
}

- (NSString *)event
{
    return [self getValueForAttribute:kEvent];
}

- (void)setEvent:(NSString *)event
{
    [self setValue:event forAttribute:kEvent];
}

- (NSArray *)messages
{
    return [self getValueForAttribute:@"unreadMessages"];
}


- (BOOL)setup
{
    return [[self getValueForAttribute:kSetup] boolValue];
}

- (void)setSetup:(BOOL)setup
{
    [self setValue:@(setup) forAttribute:kSetup];
}

- (NSDictionary *)dict
{
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    if (self.headline) {
        d[kHeadline] = self.headline;
    }
    if (self.formattedName) {
        d[kFormattedName] = self.formattedName;
    }
    if (self.talkInterests) {
        d[kTalkInterests] = self.talkInterests;
    }
    return d;
}

- (NSNumber *)notificationsOn
{
    return [self getValueForAttribute:kNotificationsOn];
}

- (void)setNotificationsOn:(NSNumber *)notificationsOn

{
    [self setValue:notificationsOn forAttribute:kNotificationsOn];
}

@end
