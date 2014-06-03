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
        [sharedManager setNumberOfConcurrentThreads:1];
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

- (NSArray *)sessions {
    static NSArray *backgroundSessions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *mutableArrayOfSessions = [[NSMutableArray alloc] initWithArray:@[]];
        for(int index = 0; index < self.numberOfConcurrentThreads; index++) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:[NSString stringWithFormat:@"%@%d", @"com.ObjectiveCDM.NSURLSession", index]];
            config.HTTPMaximumConnectionsPerHost = 3;
            NSURLSession *backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
            [mutableArrayOfSessions addObject:backgroundSession];
        }//end for
        backgroundSessions = [NSArray arrayWithArray:mutableArrayOfSessions];
    });
    return backgroundSessions;
}

// add a batch and prepare for download
- (NSArray *) addBatch:(NSArray *)arrayOfDownloadInformation {
    ObjectiveCDMDownloadBatch *batch = [[ObjectiveCDMDownloadBatch alloc] initWithFileHashAlgorithm:self.fileHashAlgorithm];
    for(NSDictionary *dictionary in arrayOfDownloadInformation) {
        [batch addTask:dictionary withNumberOfConcurrentThreads:self.numberOfConcurrentThreads];
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

- (NSArray *) downloadRateAndRemainingTime {
    int64_t rate = [currentBatch downloadRate];
    NSString *bytePerSeconds = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:rate countStyle:NSByteCountFormatterCountStyleFile]];
    
    NSString *remainingTime = [self remainingTimeGivenDownloadingRate:rate];
    
    return @[bytePerSeconds, remainingTime];
    
}

- (NSString *) remainingTimeGivenDownloadingRate:(int64_t) downloadRate {
    if(downloadRate == 0) {
        return @"Unknown";
    }//end if
    
    int64_t actualTotalBytes = 0;
    NSDictionary *bytesInfo = [currentBatch totalBytesWrittenAndReceived];
    
    if(totalBytes == 0) {
        actualTotalBytes = [(NSNumber *)bytesInfo[@"totalToBeReceivedBytes"] longLongValue];
    } else {
        actualTotalBytes = totalBytes;
    }//end else
    
    int64_t actualDownloadedBytes = [(NSNumber *)bytesInfo[@"totalDownloadedBytes"] longLongValue] + initialDownloadedBytes;
    
    float timeRemaining = (actualTotalBytes - actualDownloadedBytes) / downloadRate;
    return [self formatTimeFromSeconds:timeRemaining];
}

- (NSString *)formatTimeFromSeconds:(int64_t) numberOfSeconds {
    
    int64_t seconds = numberOfSeconds % 60;
    int64_t minutes = (numberOfSeconds / 60) % 60;
    int64_t hours = numberOfSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02lld:%02lld:%02lld", hours, minutes, seconds];
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
    downloadTaskInfo = [currentBatch addTask:dictionary withNumberOfConcurrentThreads:self.numberOfConcurrentThreads];
    if(downloadTaskInfo) {
        if(downloadTaskInfo.completed) {
            [self processCompletedDownload:downloadTaskInfo];
            [self postToUIDelegateOnIndividualDownload:downloadTaskInfo];
        } else if([currentBatch isDownloading]) {
            [currentBatch startDownloadTask:downloadTaskInfo];
        }//end if
        
        [currentBatch updateCompleteStatus];
        if(self.uiDelegate) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [self.uiDelegate didReachProgress:[self overallProgress]];
            }];
        }//end if
        if(currentBatch.completed && self.uiDelegate) {
            [self postCompleteAll];
        }//end if
    }//end if
    
    return downloadTaskInfo;
}

- (void) cancelAllOutStandingTasks {
    for(NSURLSession *session in [self sessions]) {
        [session invalidateAndCancel];
    }
}

- (void) continueInCompletedDownloads {
    [currentBatch resumeAllSuspendedTasks];
}

- (void) suspendAllOnGoingDownloads {
    [currentBatch suspendAllOnGoingDownloadTask];
}

- (void) captureInformationFromDownloadingTaskWithSessionIndex:(NSInteger)sessionIndex andCallback:(void (^)(void))completionBlock {
    if(sessionIndex == [[self sessions] count]) {
        completionBlock();
    }//end if
    else {
        NSURLSession *session = [self sessions][sessionIndex];
        [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            for(ObjectiveCDMDownloadTask *downloadTaskInfo in currentBatch.downloadObjects) {
                downloadTaskInfo.isDownloading = NO;
                NSURL *url = downloadTaskInfo.url;
                for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                    if([[url absoluteString] isEqualToString:downloadTask.originalRequest.URL.absoluteString]) {
                        int partNumber = [[downloadTask.taskDescription stringByReplacingOccurrencesOfString:@"Part-" withString:@""] intValue];
                        ObjectiveCDMDownloadTask *downloadTaskInfo = [currentBatch captureDownloadingInfoOfDownloadTask:downloadTask inPart:partNumber];
                        [self postToUIDelegateOnIndividualDownload:downloadTaskInfo];
                        downloadTaskInfo.isDownloading = YES;
                    }
                }//end for
            }//end for
            [self captureInformationFromDownloadingTaskWithSessionIndex:sessionIndex + 1 andCallback:completionBlock];
        }];
    }//end else
}

- (void) startDownloadingCurrentBatch {
    if(!currentBatch) {
        NSLog(@"You will need to set a batch to download manager first!");
        return;
    }//end if
    
    [currentBatch setDownloadingSessionsTo:[self sessions]];
    [self captureInformationFromDownloadingTaskWithSessionIndex:0 andCallback:^{
        for(ObjectiveCDMDownloadTask *downloadTaskInfo in currentBatch.downloadObjects) {
            [downloadTaskInfo captureTotalBytesDownloadedInFileParts];
            if(downloadTaskInfo.completed == YES) {
                [self processCompletedDownload:downloadTaskInfo];
                [self postToUIDelegateOnIndividualDownload:downloadTaskInfo];
            } else if(downloadTaskInfo.isDownloading == NO) {
                [currentBatch startDownloadTask:downloadTaskInfo];
            }//end if
        }
        [currentBatch updateCompleteStatus];
        if(self.uiDelegate) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                [self.uiDelegate didReachProgress:[self overallProgress]];
            }];
        }//end if
        if(currentBatch.completed && self.uiDelegate) {
            [self postCompleteAll];
        }//end if
    }];
}

- (void) postProgressToUIDelegate {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        float overallProgress = [self overallProgress];
        [self.uiDelegate didReachProgress:overallProgress];
    }];
}

- (void) postToUIDelegateOnIndividualDownload:(ObjectiveCDMDownloadTask *)task {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        task.cachedProgress = task.downloadingProgress;
        [self.uiDelegate didReachIndividualProgress:task.cachedProgress onDownloadTask:task];
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
    int partNumber = [[downloadTask.taskDescription stringByReplacingOccurrencesOfString:@"Part-" withString:@""] intValue];
    ObjectiveCDMDownloadTask *downloadTaskInfo = [currentBatch updateProgressOfDownloadURL:downloadURL withProgress:progress withTotalBytesWritten:totalBytesWritten inPart:partNumber];
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
        int partNumber = [[downloadTask.taskDescription stringByReplacingOccurrencesOfString:@"Part-" withString:@""] intValue];
        ObjectiveCDMDownloadTaskStatus finalResult = [currentBatch handleDownloadedFileAt:location forDownloadURL:downloadURL forPart:partNumber];
        if(finalResult == ObjectiveCDMDownloadTaskPartialCompleted) {
            // do nothing - just wait here
        } else if(finalResult == ObjectiveCDMDownloadTaskCompleted) {
            [self processCompletedDownload:downloadTaskInfo];
        } else if(finalResult == ObjectiveCDMDownloadTaskFailed) {
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
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.uiDelegate didFinishOnDownloadTaskUI:downloadTaskInfo];
        }];
    }//end if
    if(currentBatch.completed && self.uiDelegate) {
        [self postCompleteAll];
    }//end if
}

- (void) postCompleteAll {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self.uiDelegate didFinishAll];
    }];
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
