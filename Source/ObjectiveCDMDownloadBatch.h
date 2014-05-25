//
//  ObjectiveCDMDownloadBatch.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//


#import <Foundation/Foundation.h>

enum {
    FileHashAlgorithmMD5 = 1,
    FileHashAlgorithmSHA1 = 2,
    FileHashAlgorithmSHA512 = 3
};

typedef NSInteger FileHashAlgorithm;

@class ObjectiveCDMDownloadTask;

#import "ObjectiveCDM.h"
#import "ObjectiveCDMDownloadTask.h"

@interface ObjectiveCDMDownloadBatch : NSObject {
    NSMutableArray *downloadInputs;
    NSMutableArray *urls;
    NSURLSession *session;
    FileHashAlgorithm fileHashAlgorithm;
}

@property(nonatomic, assign) BOOL completed;

- (instancetype) initWithDownloadSession:(NSURLSession *)inputSession andFileHashAlgorithm:(FileHashAlgorithm)fileHashAlgorithm;
- (void) addTask:(NSDictionary *)taskInfo;
- (BOOL) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL;
- (NSArray *)downloadObjects;
- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url;

- (void) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten;
- (void) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask;
- (NSDictionary *) totalBytesWrittenAndReceived;
- (void)startDownloadTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo;
- (void) continueAllInCompletedDownloadTask;
- (void) suspendAllOnGoingDownloadTask;
- (void) resumeAllSuspendedTasks;
@end
