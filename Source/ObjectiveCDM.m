//
//  ObjectiveCDM.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import "ObjectiveCDM.h"

@implementation ObjectiveCDM

+ (instancetype) sharedInstance {
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
        [sharedManager setInitialDownloadedBytes:0];
        [sharedManager setTotalBytes:0];
        ((ObjectiveCDM *)sharedManager).fileHashAlgorithm = FileHashAlgorithmSHA1;
        [sharedManager listenToInternetConnectionChange];
    });
    return sharedManager;
}

- (void) setInitialDownloadedBytes:(int64_t)initialDownloadedBytesInput {
    initialDownloadedBytes = initialDownloadedBytesInput;
}

- (void) setTotalBytes:(int64_t)totalBytesInput {
    totalBytes = totalBytesInput;
}

- (float) overallProgress {
    int64_t actualTotalBytes = 0;
    NSDictionary *bytesInfo = [currentBatch totalBytesWrittenAndReceived];

    if(totalBytes == 0) {
        actualTotalBytes = [(NSNumber *)bytesInfo[@"totalToBeReceivedBytes"] longLongValue];
    } else {
        actualTotalBytes = totalBytes;
    }//end else
    
    int64_t actualDownloadedBytes = [(NSNumber *)bytesInfo[@"totalDownloadedBytes"] longLongValue] + initialDownloadedBytes;
    
    if(actualTotalBytes == 0) {
        return 0;
    }//end if
    float progress = (double)actualDownloadedBytes / (double)actualTotalBytes;
    return progress;
}

- (NSURLSession *)session {
    static NSURLSession *backgroundSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.ObjectiveCDM.NSURLSession"];
        config.HTTPMaximumConnectionsPerHost = 4;
        backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    return backgroundSession;
}

// add a batch and prepare for download
- (NSArray *) addBatch:(NSArray *)arrayOfDownloadInformation {
    ObjectiveCDMDownloadBatch *batch = [[ObjectiveCDMDownloadBatch alloc] initWithFileHashAlgorithm:self.fileHashAlgorithm];
    for(NSDictionary *dictionary in arrayOfDownloadInformation) {
        [batch addTask:dictionary];
    }//end for
    currentBatch = batch;
    return [currentBatch downloadObjects];
}

- (NSArray *) downloadingTasks {
    if(currentBatch) {
        return [currentBatch downloadObjects];
    } else {
        return @[];
    }
}

- (void) startDownloadingCurrentBatch {
    [self startADownloadBatch:currentBatch];
}

- (void) downloadBatch:(NSArray *)arrayOfDownloadInformation {
    [self addBatch:arrayOfDownloadInformation];
    [self startDownloadingCurrentBatch];
}

- (ObjectiveCDMDownloadTask *) addDownloadTask:(NSDictionary *)dictionary {
    ObjectiveCDMDownloadTask *downloadTaskInfo = nil;
    if(!currentBatch) {
        currentBatch = [[ObjectiveCDMDownloadBatch alloc] initWithFileHashAlgorithm:self.fileHashAlgorithm];
    }
    downloadTaskInfo = [currentBatch addTask:dictionary];
    if(downloadTaskInfo) {
        NSLog(@"current batch is downloading %d", [currentBatch isDownloading]);
        if(downloadTaskInfo.completed) {
            [self processCompletedDownload:downloadTaskInfo];
            [self postToUIDelegateOnIndividualDownload:downloadTaskInfo];
        } else if([currentBatch isDownloading]) {
            [currentBatch startDownloadTask:downloadTaskInfo];
        }//end if
        
        [currentBatch updateCompleteStatus];
        if(self.uiDelegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.uiDelegate didReachProgress:[self overallProgress]];
            });
        }//end if
        if(currentBatch.completed) {
            [self postCompleteAll];
        }//end if
    }//end if
    
    return downloadTaskInfo;
}

- (void) cancelAllOutStandingTasks {
    [self.session invalidateAndCancel];
}

- (void) continueInCompletedDownloads {
    [currentBatch resumeAllSuspendedTasks];
}

- (void) suspendAllOnGoingDownloads {
    [currentBatch suspendAllOnGoingDownloadTask];
}

- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch {
    [batch setDownloadingSessionTo:[self session]];
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for(ObjectiveCDMDownloadTask *downloadTaskInfo in batch.downloadObjects) {
            BOOL isDownloading = NO;
            NSURL *url = downloadTaskInfo.url;
            for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                if([[url absoluteString] isEqualToString:downloadTask.originalRequest.URL.absoluteString]) {
                    ObjectiveCDMDownloadTask *downloadTaskInfo = [batch captureDownloadingInfoOfDownloadTask:downloadTask];
                    [self postToUIDelegateOnIndividualDownload:downloadTaskInfo];
                    isDownloading = YES;
                }
            }//end for
            if(downloadTaskInfo.completed == YES) {
                [self processCompletedDownload:downloadTaskInfo];
                [self postToUIDelegateOnIndividualDownload:downloadTaskInfo];
            } else if(isDownloading == NO) {
                [batch startDownloadTask:downloadTaskInfo];
            }//end if
        }//end for
        [batch updateCompleteStatus];
        if(self.uiDelegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.uiDelegate didReachProgress:[self overallProgress]];
            });
        }//end if
        if(currentBatch.completed) {
            [self postCompleteAll];
        }//end if
    }];
}

- (void) postProgressToUIDelegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        float overallProgress = [self overallProgress];
        [self.uiDelegate didReachProgress:overallProgress];
    });
}

- (void) postToUIDelegateOnIndividualDownload:(ObjectiveCDMDownloadTask *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        task.cachedProgress = task.downloadingProgress;
        [self.uiDelegate didReachIndividualProgress:task.cachedProgress onDownloadTask:task];
    });
}

- (void) postDownloadErrorToUIDelegate:(ObjectiveCDMDownloadTask *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.uiDelegate didHitDownloadErrorOnTask:task];
    });
}

# pragma NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask
didCompleteWithError:(NSError *)error {
    if(error) {
        NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
        ObjectiveCDMDownloadTask *downloadTaskInfo = [currentBatch downloadInfoOfTaskUrl:downloadURL];
        if(downloadTaskInfo) {
            [downloadTaskInfo captureReceivedError:error];
            [currentBatch redownloadRequestOfTask:downloadTaskInfo];
            if(self.uiDelegate) {
                [self postDownloadErrorToUIDelegate:downloadTaskInfo];
            }//end if
        }//end if
    }//end if
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
    float progress = (totalBytesWritten * 1.0 / totalBytesExpectedToWrite);
    ObjectiveCDMDownloadTask *downloadTaskInfo = [currentBatch updateProgressOfDownloadURL:downloadURL withProgress:progress withTotalBytesWritten:totalBytesWritten];
    if(downloadTaskInfo) {
        if(self.uiDelegate) {
            [self postProgressToUIDelegate];
            [self postToUIDelegateOnIndividualDownload:downloadTaskInfo];
        }//end if
    }//end if
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTaskInfo didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
    ObjectiveCDMDownloadTask *downloadTaskInfo = [currentBatch downloadInfoOfTaskUrl:downloadURL];
    if(downloadTaskInfo) {
        BOOL finalResult = [currentBatch handleDownloadedFileAt:location forDownloadURL:downloadURL];
        if(finalResult) {
            [self processCompletedDownload:downloadTaskInfo];
        } else {
            // clean up and redownload file
            [downloadTaskInfo cleanUp];
            [currentBatch startDownloadTask:downloadTaskInfo];
            [self postProgressToUIDelegate];
        } //end else
    }//end if
    else {
        // ignore -- not my task
    }//end else
}

- (void) processCompletedDownload:(ObjectiveCDMDownloadTask *)downloadTaskInfo {
    if(self.dataDelegate) {
        [self.dataDelegate didFinishDownloadTask:downloadTaskInfo];
    }//end if
    if(self.uiDelegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.uiDelegate didFinishOnDownloadTaskUI:downloadTaskInfo];
        });
    }//end if
    if(currentBatch.completed) {
        [self postCompleteAll];
    }//end if
}

- (void) postCompleteAll {
    
    if(self.dataDelegate) {
        [self.dataDelegate didFinishAllForDataDelegate];
    }//end if
    
    if(self.uiDelegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.uiDelegate didFinishAll];
        });
    }//end if
}

// Checks if we have an internet connection or not
- (void) listenToInternetConnectionChange {
    internetReachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    // Internet is reachable
    __weak ObjectiveCDM* _weakSelf = self;
    internetReachability.reachableBlock = ^(Reachability *reach) {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Yayyy, we have the interwebs!");
            [_weakSelf continueInCompletedDownloads];
        });
    };
    
    // Internet is not reachable
    internetReachability.unreachableBlock = ^(Reachability *reach) {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Someone broke the internet :(");
            [_weakSelf suspendAllOnGoingDownloads];
        });
    };
    
    [internetReachability startNotifier];
}


@end
