//
//  ObjectiveCDMDownloadBatch.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import "ObjectiveCDMDownloadBatch.h"

@implementation ObjectiveCDMDownloadBatch

- (instancetype) initWithDownloadSession:(NSURLSession *)inputSession andFileHashAlgorithm:(FileHashAlgorithm)fileHashAlgorithmInput {
    self = [super init];
    if(self) {
        downloadInputs = [[NSMutableArray alloc] initWithArray:@[]];
        urls = [[NSMutableArray alloc] initWithArray:@[]];
        session = inputSession;
        fileHashAlgorithm = fileHashAlgorithmInput;
    }//end if
    return self;
}

- (void) addTask:(NSDictionary *)taskInfo {
    NSString *urlString = nil;
    BOOL isURLString = YES;
    if([taskInfo[@"url"] isKindOfClass:[NSURL class]]) {
        urlString = [((NSURL *)taskInfo[@"url"]) absoluteString];
        isURLString = NO;
    }//end if
    else {
        urlString = taskInfo[@"url"];
    }//end else
    
    NSString *destination = taskInfo[@"destination"];
    int64_t totalExpectedToWrite = 0;
    if(taskInfo[@"fileSize"]) {
        totalExpectedToWrite = [(NSNumber *)taskInfo[@"fileSize"] longLongValue];
    }
    if([self isTaskExistWithURL:urlString andDestination:destination] == NO) {
        ObjectiveCDMDownloadTask *downloadTask = nil;
        if(isURLString) {
            downloadTask = [[ObjectiveCDMDownloadTask alloc]
                                initWithURLString:urlString
                                  withDestination:destination
                    andTotalBytesExepectedToWrite:totalExpectedToWrite
                                      andChecksum:taskInfo[@"checksum"]
                              andFileHashAlgorithm:fileHashAlgorithm];
        } else {
            downloadTask = [[ObjectiveCDMDownloadTask alloc]
                            initWithURLString:taskInfo[@"url"]
                              withDestination:destination
                andTotalBytesExepectedToWrite:totalExpectedToWrite
                                  andChecksum:taskInfo[@"checksum"]
                         andFileHashAlgorithm:fileHashAlgorithm];
;
        }//end else
        
        [urls addObject:urlString];
        [downloadInputs addObject:downloadTask];
    }//end if
}

- (BOOL) isTaskExistWithURL:(NSString *)urlString andDestination:(NSString *)destination {
    return [urls indexOfObject:urlString] != NSNotFound;
}

- (BOOL) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL {
    NSError *movingFileError;
    ObjectiveCDMDownloadTask *downloadTaskInfo = [self downloadInfoOfTaskUrl:downloadURL];
    NSString *destinationPath = downloadTaskInfo.destination;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    [fileManager moveItemAtPath:downloadedFileLocation.path toPath:destinationPath error:&movingFileError];
    
    if(movingFileError) {
        NSLog(@"Error: %@", movingFileError.localizedDescription);
        return NO;
    } else {
        BOOL isVerified = [downloadTaskInfo verifyDownload];
        if(isVerified) {
            [self updateCompleteStatus];
        }//end if
        return isVerified;
    }//end else
}

- (void) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    // task is already inside the session - do nothing
    NSURL *url = downloadTask.originalRequest.URL;
    ObjectiveCDMDownloadTask *downloadTaskInfo = [self downloadInfoOfTaskUrl:url.absoluteString];
    downloadTaskInfo.totalBytesWritten = downloadTask.countOfBytesReceived;

    if(downloadTaskInfo.totalBytesExpectedToWrite == 0) {
        downloadTaskInfo.totalBytesExpectedToWrite = downloadTask.countOfBytesExpectedToReceive;
    }//end if
}

- (void) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten {
    [self downloadInfoOfTaskUrl:url].totalBytesWritten = totalBytesWritten;
}

- (NSArray *)downloadObjects {
    return downloadInputs;
}

- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url {
    return downloadInputs[[urls indexOfObject:url]];
}

- (void)startDownloadURL:(ObjectiveCDMDownloadTask *)downloadTaskInfo {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadTaskInfo.url];
    if(downloadTaskInfo.totalBytesExpectedToWrite == 0) {
        [self requestForTotalBytesForURL:downloadTaskInfo.url withCallback:^(int64_t totalBytesToBeReceived)  {
            downloadTaskInfo.totalBytesExpectedToWrite = totalBytesToBeReceived;
            [self downloadRequest:request];
        }];
    } else {
        [self downloadRequest:request];
    }//end else
}

- (void) downloadRequest:(NSMutableURLRequest *)request {
    [request setTimeoutInterval:90.0];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask resume];
}

- (void) requestForTotalBytesForURL:(NSURL *)url withCallback:(void (^)(int64_t))completed {
    NSMutableURLRequest *headRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [headRequest setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    [headRequest setHTTPMethod:@"HEAD"];
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *headTask = [sharedSession dataTaskWithRequest:headRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completed(response.expectedContentLength);
    }];
    [headTask resume];
}

- (NSDictionary *) totalBytesWrittenAndReceived {
    int64_t totalDownloadedBytes = 0;
    int64_t totalBytesExpectedToReceive = 0;
    for(ObjectiveCDMDownloadTask *downloadTaskInfo in downloadInputs) {
        totalDownloadedBytes += downloadTaskInfo.totalBytesWritten;
        totalBytesExpectedToReceive += downloadTaskInfo.totalBytesExpectedToWrite;
    }//end for
    
    return @{
        @"totalDownloadedBytes": [NSNumber numberWithLongLong:totalDownloadedBytes],
        @"totalToBeReceivedBytes": [NSNumber numberWithLongLong:totalBytesExpectedToReceive]
    };
}

- (void) updateCompleteStatus {
    for(ObjectiveCDMDownloadTask *task in downloadInputs) {
        // any incompleted task will mark the batch's completed as no and return
        if(task.completed == NO) {
            self.completed = NO;
            return;
        }//end if
    }
    
    self.completed = YES;
}

@end
