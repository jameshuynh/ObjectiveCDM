//
//  ObjectiveCDMDownloadBatch.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import <Foundation/Foundation.h>
#import "ObjectiveCDMDownloadTask.h"

@interface ObjectiveCDMDownloadBatch : NSObject {
    NSMutableArray *downloadInputs;
    NSMutableArray *urls;
}

@property(nonatomic, assign) BOOL isCompleted;

- (void) addTask:(NSDictionary *)taskInfo;

- (void) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL;
- (NSArray *)downloadObjects;
- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url;

- (void) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten;
- (void) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask;
- (NSDictionary *) totalBytesWrittenAndReceived;
- (void)startDownloadURL:(ObjectiveCDMDownloadTask *)downloadTaskInfo withURLSession:(NSURLSession *)session;
@end
