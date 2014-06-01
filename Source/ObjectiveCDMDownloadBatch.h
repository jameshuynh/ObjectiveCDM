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

enum {
    ObjectiveCDMDownloadTaskPartialCompleted = 0,
    ObjectiveCDMDownloadTaskCompleted = 1,
    ObjectiveCDMDownloadTaskFailed = -1,
};

typedef NSInteger ObjectiveCDMDownloadTaskStatus;

@class ObjectiveCDMDownloadTask;

#import "ObjectiveCDM.h"
#import "ObjectiveCDMDownloadTask.h"

@interface ObjectiveCDMDownloadBatch : NSObject {
    NSMutableArray *downloadInputs;
    NSMutableArray *urls;
    NSArray *sessions;
    FileHashAlgorithm fileHashAlgorithm;
}

@property(nonatomic, assign) BOOL completed;

- (instancetype) initWithFileHashAlgorithm:(FileHashAlgorithm)fileHashAlgorithmInput;
- (ObjectiveCDMDownloadTask *) addTask:(NSDictionary *)taskInfo withNumberOfConcurrentThreads:(int)threadsNumber;
- (ObjectiveCDMDownloadTaskStatus) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL forPart:(int)partNumber;
- (NSArray *)downloadObjects;
- (void) setDownloadingSessionsTo:(NSArray *)inputSessions;
- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url;

- (void) updateCompleteStatus;
- (ObjectiveCDMDownloadTask *) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten inPart:(int)partNumber;
- (ObjectiveCDMDownloadTask *) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask inPart:(int)partNumber;
- (NSDictionary *) totalBytesWrittenAndReceived;
- (void) startDownloadTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo;
- (void) continueAllInCompletedDownloadTask;
- (void) suspendAllOnGoingDownloadTask;
- (void) resumeAllSuspendedTasks;
- (BOOL) isDownloading;

@end
