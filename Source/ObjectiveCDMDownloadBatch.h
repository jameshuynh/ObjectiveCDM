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
    kUnitStringBinaryUnits     = 1 << 0,
    kUnitStringOSNativeUnits   = 1 << 1,
    kUnitStringLocalizedFormat = 1 << 2
};

typedef NSInteger ObjectiveCDMDownloadTaskStatus;

@class ObjectiveCDMDownloadTask;

#import "ObjectiveCDM.h"
#import "ObjectiveCDMDownloadTask.h"

@interface ObjectiveCDMDownloadBatch : NSObject {
    NSMutableArray *downloadInputs;
    NSMutableArray *urls;
    NSURLSession *session;
    FileHashAlgorithm fileHashAlgorithm;
    int64_t numberOfBytesDownloadedSinceStart;
    NSDate *startTime;
}

@property(nonatomic, assign) BOOL completed;

- (instancetype) initWithFileHashAlgorithm:(FileHashAlgorithm)fileHashAlgorithmInput;
- (ObjectiveCDMDownloadTask *) addTask:(NSDictionary *)taskInfo;
- (BOOL) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL;
- (NSArray *)downloadObjects;
- (void) setDownloadingSessionTo:(NSURLSession *)inputSession;
- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url;

- (void) updateCompleteStatus;
- (ObjectiveCDMDownloadTask *) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten;
- (ObjectiveCDMDownloadTask *) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask;
- (NSDictionary *) totalBytesWrittenAndReceived;
- (void) startDownloadTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo;
- (void) continueAllInCompletedDownloadTask;
- (void) suspendAllOnGoingDownloadTask;
- (void) resumeAllSuspendedTasks;
- (BOOL) isDownloading;
- (void) redownloadRequestOfTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo;

- (int64_t) downloadRate;
- (double) elapsedSeconds;
@end
