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
    return (double)actualDownloadedBytes / (double)actualTotalBytes;
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

- (void) downloadBatch:(NSArray *)arrayOfDownloadInformation {
    ObjectiveCDMDownloadBatch *batch = [[ObjectiveCDMDownloadBatch alloc] initWithDownloadSession:[self session] andFileHashAlgorithm:self.fileHashAlgorithm];
    for(NSDictionary *dictionary in arrayOfDownloadInformation) {
        [batch addTask:dictionary];
    }//end for
    [self startADownloadBatch:batch];
}

- (void) downloadURL:(NSString *)urlString to:(NSString *)destination {
    ObjectiveCDMDownloadBatch *batch = [[ObjectiveCDMDownloadBatch alloc] initWithDownloadSession:[self session] andFileHashAlgorithm:self.fileHashAlgorithm];
    [batch addTask:@{@"url": urlString, @"destination":destination}];
    [self startADownloadBatch:batch];
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
    currentBatch = batch;
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for(ObjectiveCDMDownloadTask *downloadTaskInfo in batch.downloadObjects) {
            BOOL isDownloading = NO;
            NSURL *url = downloadTaskInfo.url;
            for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                if([[url absoluteString] isEqualToString:downloadTask.originalRequest.URL.absoluteString]) {
                    [batch captureDownloadingInfoOfDownloadTask:downloadTask];
                    isDownloading = YES;
                }
            }//end for
            if(isDownloading == NO) {
                [batch startDownloadTask:downloadTaskInfo];
            }//end if
        }//end for
        if(self.uiDelegate) {
            [self.uiDelegate didReachProgress:[self overallProgress]];
        }//end if
    }];
}

- (void) postProgressToUIDelegate {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        float overallProgress = [self overallProgress];
        NSLog(@"Overall Progress is %f", overallProgress);
        [self.uiDelegate didReachProgress:[self overallProgress]];
    }];
}

- (void) postDownloadErrorToUIDelegate:(ObjectiveCDMDownloadTask *)task {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self.uiDelegate didHitDownloadErrorOnTask:task];
    }];
}

# pragma NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask
didCompleteWithError:(NSError *)error {
    if(error) {
        NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
        ObjectiveCDMDownloadTask *downloadTaskInfo = [currentBatch downloadInfoOfTaskUrl:downloadURL];
        if(downloadTaskInfo) {
            downloadTaskInfo.error = error;
            if(self.uiDelegate) {
                [self postDownloadErrorToUIDelegate:downloadTaskInfo];
            }//end if
        }//end if
    }//end if
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
    float progress = (totalBytesWritten * 1.0 / totalBytesExpectedToWrite);
    [currentBatch updateProgressOfDownloadURL:downloadURL withProgress:progress withTotalBytesWritten:totalBytesWritten];
    if(self.uiDelegate) {
        [self postProgressToUIDelegate];
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
            if(self.dataDelegate) {
                [self.dataDelegate didFinishDownloadObject:[currentBatch downloadInfoOfTaskUrl:downloadURL]];
            }//end if
            if(currentBatch.completed && self.uiDelegate) {
                [self.uiDelegate didFinishAll];
            }//end if
        } else {
            // clean up and redownload file
            [downloadTaskInfo cleanUp];
            [currentBatch startDownloadTask:downloadTaskInfo];
            [self postProgressToUIDelegate];
        }
    }//end if
    else {
        // ignore -- not my task
    }
}

// Checks if we have an internet connection or not
- (void)listenToInternetConnectionChange {
    internetReachability = [Reachability reachabilityWithHostName:@"www.google.com"];
    
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
