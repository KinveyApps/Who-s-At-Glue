//
//  LicenseTableViewController.m
//  WhosAtGlue
//
//  Created by Michael Katz on 4/23/14.
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

#import "LicenseTableViewController.h"

@interface LicenseTableViewController ()

@end

@implementation LicenseTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableString* string = [NSMutableString string];
        for (NSString* path in self.paths) {
            NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
            [string appendString:contents];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textView.text = string;
        });
    });
}

@end
