//
//  ObjectiveCDM.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import <Foundation/Foundation.h>
#import "ObjectiveCDMDownloadBatch.h"
#import "ObjectiveCDMDownloadTask.h"
#import "Reachability.h"

@class ObjectiveCDMDownloadBatch;
@protocol ObjectiveCDMUIDelegate;
@protocol ObjectiveCDMDataDelegate;

@interface ObjectiveCDM : NSObject <NSURLSessionDownloadDelegate> {
    NSURLSession *downloadSession;
    ObjectiveCDMDownloadBatch* currentBatch;
    int64_t initialDownloadedBytes;
    int64_t totalBytes;
    Reachability *internetReachability;
}

+ (instancetype) sharedInstance;
- (void) setInitialDownloadedBytes:(int64_t)initialDownloadedBytes;
- (void) setTotalBytes:(int64_t)totalBytes;
- (void) downloadBatch:(NSArray *)arrayOfDownloadInformation;
- (void) downloadURL:(NSString *)urlString to:(NSString *)destination;
- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch;
- (void) cancelAllOutStandingTasks;
- (void) continueInCompletedDownloads;
- (void) suspendAllOnGoingDownloads;

@property(nonatomic, assign) FileHashAlgorithm fileHashAlgorithm;
@property(nonatomic, retain) id<ObjectiveCDMUIDelegate> uiDelegate;
@property(nonatomic, retain) id<ObjectiveCDMDataDelegate> dataDelegate;

@end

@protocol ObjectiveCDMUIDelegate
- (void) didReachProgress:(float)progress;
- (void) didHitDownloadErrorOnTask:(ObjectiveCDMDownloadTask* ) task;
- (void) didFinishAll;
- (void) didFinishOnDownloadTaskUI:(ObjectiveCDMDownloadTask *) task;
- (void) didReachIndividualProgress:(float)progress onDownloadTask:(ObjectiveCDMDownloadTask* ) task;
@end

@protocol ObjectiveCDMDataDelegate
- (void) didFinishDownloadTask:(ObjectiveCDMDownloadTask *)downloadInfo;
@end