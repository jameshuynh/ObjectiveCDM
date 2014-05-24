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

@class ObjectiveCDMDownloadBatch;
@protocol ObjectiveCDMUIDelegate;
@protocol ObjectiveCDMDataDelegate;

@interface ObjectiveCDM : NSObject <NSURLSessionDownloadDelegate> {
    NSURLSession *downloadSession;
    ObjectiveCDMDownloadBatch* currentBatch;
    int64_t initialDownloadedBytes;
    int64_t totalBytes;
}

+ (instancetype) sharedInstance;
- (void) setInitialDownloadedBytes:(int64_t)initialDownloadedBytes;
- (void) setTotalBytes:(int64_t)totalBytes;
- (void) downloadBatch:(NSArray *)arrayOfDownloadInformation;
- (void) downloadURL:(NSString *)urlString to:(NSString *)destination;
- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch;
- (void) cancelAllOutStandingTasks;

@property(nonatomic, assign) FileHashAlgorithm fileHashAlgorithm;
@property(nonatomic, retain) id<ObjectiveCDMUIDelegate> uiDelegate;
@property(nonatomic, retain) id<ObjectiveCDMDataDelegate> dataDelegate;

@end

@protocol ObjectiveCDMUIDelegate
- (void) didReachProgress:(float)progress;
- (void) didFinish;
@end

@protocol ObjectiveCDMDataDelegate
- (void) didFinishDownloadObject:(ObjectiveCDMDownloadTask *)downloadInfo;
@end