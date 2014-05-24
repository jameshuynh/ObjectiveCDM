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
    NSLog(@"total progress %f", (double)actualDownloadedBytes / (double)actualTotalBytes);
    return (double)actualDownloadedBytes / (double)actualTotalBytes;
}

- (NSURLSession *)session {
    static NSURLSession *backgroundSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.rubify.ObjectiveCDM"];
        backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    return backgroundSession;
}

- (void) downloadBatch:(NSArray *)arrayOfDownloadInformation {
    ObjectiveCDMDownloadBatch *batch = [[ObjectiveCDMDownloadBatch alloc] init];
    for(NSDictionary *dictionary in arrayOfDownloadInformation) {
        NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentDirectory, dictionary[@"destination"]];
        [batch addTaskWithURLString:dictionary[@"url"] andDestination:fullPath];
    }//end for
    [self startADownloadBatch:batch];
}

- (void) downloadURL:(NSString *)urlString to:(NSString *)destination {
    ObjectiveCDMDownloadBatch *batch = [[ObjectiveCDMDownloadBatch alloc] init];
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentDirectory, destination];
    [batch addTaskWithURLString:urlString andDestination:fullPath];
    [self startADownloadBatch:batch];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    // NSLog(@"Downloading Progress %f - %@", totalBytesWritten * 1.0 / totalBytesExpectedToWrite, session.configuration.identifier);
    
    NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
    [currentBatch updateProgressOfDownloadURL:downloadURL withProgress:(totalBytesWritten * 1.0 / totalBytesExpectedToWrite) withTotalBytesWritten:totalBytesWritten];
    if(self.uiDelegate) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self.uiDelegate didReachProgress:[self overallProgress]];
        }];
        
    }//end if
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
    [currentBatch handleDownloadedFileAt:location forDownloadURL:downloadURL];
    if(self.dataDelegate) {
        [self.dataDelegate didFinishDownloadObject:[currentBatch downloadInfoOfTaskUrl:downloadURL]];
    }//end if
}

- (void) cancelAllOutStandingTasks {
    [self.session invalidateAndCancel];
}

- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch {
    currentBatch = batch;
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for(NSMutableDictionary *dictionary in batch.downloadObjects) {
            BOOL isDownloading = NO;
            NSURL *url = dictionary[@"url"];
            NSLog(@"url %@", url);
            for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                if([[url absoluteString] isEqualToString:downloadTask.originalRequest.URL.absoluteString]) {
                    [batch captureDownloadingInfoOfDownloadTask:downloadTask];
                    isDownloading = YES;
                }
            }//end for
            if(isDownloading == NO) {
                [batch startDownloadURL:dictionary withURLSession:self.session];
            }//end if
        }//end for
        if(self.uiDelegate) {
            [self.uiDelegate didReachProgress:[self overallProgress]];
        }//end if
    }];
}

@end
