/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

//
//  AppDelegate.m
//  Test Offline
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

#import "CDVUrl.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Cordova/CDVViewController.h>

@implementation CDVUrl

- (void)pluginInitialize {
    [NSURLProtocol registerClass:[UnifaceAppURLProtocol class]];
}
@end

/*******************************************************/
/* Implement the protocol handler for "uniface-app://" */
/*******************************************************/
NSString* const kUnifacePrefix = @"uniface-app";
NSString* const kUnifaceServer = @"-uniface-app-";

@implementation UnifaceAppURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)theRequest
{
    NSURL* theUrl = [theRequest URL];
    
    
    if ([[theUrl host] isEqualToString:kUnifaceServer] || [[theUrl scheme] isEqualToString:kUnifacePrefix]) {
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request
{
    // NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    return request;
}

- (void)startLoading
{
    NSURL *url = [[self request] URL];
    NSString *filePath;

    if ([[url host] isEqualToString:kUnifaceServer]){
        // Correctly formed URL https://-uniface-app-/filename
        filePath = [url path];
    } else if ([[url scheme] isEqualToString:kUnifacePrefix]) {
        if ([[url host] length] == 0) {
            // Correctly formed URL uniface-app:///filename
            filePath = [url path];
        } else if ([[url path] length] == 0){
            // Badly formed URL uniface-app://filename
            filePath = [url host];
        } else {
            // Badly formed URL uniface-app://filename/deeper_path
            filePath = [NSString stringWithFormat: @"%@/%@", [url host], [url path]];
        }
    }
    
    // Load data from the file
    NSString *fileExtension = [filePath pathExtension];
    NSString *cordovePathString = [NSString stringWithFormat: @"www/%@", [filePath stringByDeletingPathExtension]];
    NSData* data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:cordovePathString ofType:fileExtension]];
    
    // Determine the mime type
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *mime = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    
    // Set the return Data
    [self sendResponseWithResponseCode:200 data:data mimeType:mime];
    
    return;
}

- (void)stopLoading
{
    // do any cleanup here
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest*)requestA toRequest:(NSURLRequest*)requestB
{
    return NO;
}

- (void)sendResponseWithResponseCode:(NSInteger)statusCode data:(NSData*)data mimeType:(NSString*)mimeType
{
    if (mimeType == nil) {
        mimeType = @"text/plain";
    }
    
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:[[self request] URL] statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type" : mimeType}];
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    if (data != nil) {
        [[self client] URLProtocol:self didLoadData:data];
    }
    [[self client] URLProtocolDidFinishLoading:self];
}

@end
