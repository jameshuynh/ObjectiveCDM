//
//  ObjectiveCDMDownload.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 23/5/14.
//
//

#import "ObjectiveCDMDownload.h"

@implementation ObjectiveCDMDownload

- (void) start {
    NSURLSessionDownloadTask *downloadTask = [_downloadSession downloadTaskWithRequest:_request];
    [downloadTask resume];
}

@end
