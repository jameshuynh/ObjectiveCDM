//
//  ObjectiveCDMDownloadBatch.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import "ObjectiveCDMDownloadBatch.h"

@implementation ObjectiveCDMDownloadBatch

- (instancetype) initWithFileHashAlgorithm:(FileHashAlgorithm)fileHashAlgorithmInput {
    self = [super init];
    if(self) {
        downloadInputs = [[NSMutableArray alloc] initWithArray:@[]];
        urls = [[NSMutableArray alloc] initWithArray:@[]];
        fileHashAlgorithm = fileHashAlgorithmInput;
        startTime = [NSDate date];
        numberOfBytesDownloadedSinceStart = 0;
    }//end if
    return self;
}

- (ObjectiveCDMDownloadTask *) addTask:(NSDictionary *)taskInfo withNumberOfConcurrentThreads:(int)threadsNumber {
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
                             andFileHashAlgorithm:fileHashAlgorithm
                            andNumberOfConnections:threadsNumber];
        } else {
            downloadTask = [[ObjectiveCDMDownloadTask alloc]
                            initWithURLString:taskInfo[@"url"]
                              withDestination:destination
                andTotalBytesExepectedToWrite:totalExpectedToWrite
                                  andChecksum:taskInfo[@"checksum"]
                         andFileHashAlgorithm:fileHashAlgorithm
                       andNumberOfConnections:threadsNumber];
;
        }//end else
        if(taskInfo[@"identifier"]) {
            downloadTask.identifier = taskInfo[@"identifier"];
        }//end if
        downloadTask.position = [downloadInputs count];
        [urls addObject:urlString];
        [downloadInputs addObject:downloadTask];
        
        return downloadTask;
    }//end if
    
    return nil;
}

- (BOOL) isTaskExistWithURL:(NSString *)urlString andDestination:(NSString *)destination {
    return [urls indexOfObject:urlString] != NSNotFound;
}

- (ObjectiveCDMDownloadTaskStatus) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL forPart:(int)partNumber {
    NSError *movingFileError;
    ObjectiveCDMDownloadTask *downloadTaskInfo = [self downloadInfoOfTaskUrl:downloadURL];
    NSString *destinationPath = [NSString stringWithFormat:@"%@.part%d", downloadTaskInfo.destination, partNumber];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtPath:downloadedFileLocation.path toPath:destinationPath error:&movingFileError];
    
    if(movingFileError) {
        NSLog(@"Error: %@", movingFileError.localizedDescription);
        return NO;
    } else {
        if([downloadTaskInfo checkDownloadCompleted]) {
            if([downloadTaskInfo mergeAndVerifyDownload]) {
                [self updateCompleteStatus];
                return ObjectiveCDMDownloadTaskCompleted;
            } else {
                return ObjectiveCDMDownloadTaskFailed;
            }
        }//end if
        else {
            return ObjectiveCDMDownloadTaskPartialCompleted;
        }//end else
        // finish all the parts
    }//end else
}

- (ObjectiveCDMDownloadTask *) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask inPart:(int)partNumber {
    // task is already inside the session - do nothing
    NSURL *url = downloadTask.originalRequest.URL;
    ObjectiveCDMDownloadTask *downloadTaskInfo = [self downloadInfoOfTaskUrl:url.absoluteString];
    if(downloadTaskInfo) {
        [downloadTaskInfo setBytesWrittenForDownloadPart:partNumber withNumberOfBytes:downloadTask.countOfBytesReceived];
        
        if(downloadTaskInfo.totalBytesExpectedToWrite == 0) {
            downloadTaskInfo.totalBytesExpectedToWrite = downloadTask.countOfBytesExpectedToReceive;
        }//end if
    }//end if
    return downloadTaskInfo;
}

- (ObjectiveCDMDownloadTask *) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten inPart:(int)partNumber {
    ObjectiveCDMDownloadTask *downloadTask = [self downloadInfoOfTaskUrl:url];
    if(downloadTask) {
        numberOfBytesDownloadedSinceStart += totalBytesWritten - [downloadTask.totalBytesWrittenArray[partNumber] longLongValue];
        [downloadTask setBytesWrittenForDownloadPart:partNumber withNumberOfBytes:totalBytesWritten];
    }//end if
    
    return downloadTask;
}

- (NSArray *)downloadObjects {
    return downloadInputs;
}

- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url {
    NSInteger indexOfObject = [urls indexOfObject:url];
    if(indexOfObject != NSNotFound) {
        return downloadInputs[[urls indexOfObject:url]];
    } else {
        return nil;
    }//end else
}

- (void)startDownloadTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadTaskInfo.url];
    if(downloadTaskInfo.totalBytesExpectedToWrite == 0) {
        [self requestForTotalBytesForURL:downloadTaskInfo.url withCallback:^(int64_t totalBytesToBeReceived)  {
            downloadTaskInfo.totalBytesExpectedToWrite = totalBytesToBeReceived;            
            [self downloadRequest:request ofTask:downloadTaskInfo];
        }];
    } else {
        [self downloadRequest:request ofTask:downloadTaskInfo];
    }//end else
}

- (void) downloadRequest:(NSMutableURLRequest *)request ofTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo {
    [request setTimeoutInterval:90.0];
    int partNumber = 0;
    for(NSURLSession *session in sessions) {
        if([downloadTaskInfo alreadyDownloadedPart:partNumber]) {
            continue;
        }//end if
        [request setValue:[downloadTaskInfo rangeOfPart:partNumber] forHTTPHeaderField:@"Range"];
        
        if(downloadTaskInfo.error) {
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithResumeData:downloadTaskInfo.error.userInfo[NSURLSessionDownloadTaskResumeData]];
            downloadTask.taskDescription = [NSString stringWithFormat:@"Part-%d", partNumber];
            [downloadTask resume];
            downloadTaskInfo.error = nil;
        } else {
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
            downloadTask.taskDescription = [NSString stringWithFormat:@"Part-%d", partNumber];
            [downloadTask resume];
        }//end else
        partNumber++;
    }//end for
    
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
    }//end for
    
    self.completed = YES;
}

- (void) setDownloadingSessionsTo:(NSArray *)inputSession {
    sessions = inputSession;
}

- (void) continueAllInCompletedDownloadTask {
    for(ObjectiveCDMDownloadTask *downloadTask in downloadInputs) {
        if(downloadTask.completed == NO) {
            [self startDownloadTask:downloadTask];
        }//end if
    }
}

- (void) resumeAllSuspendedTasks {
    for(NSURLSession *session in sessions) {
        [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                NSString *urlString = downloadTask.originalRequest.URL.absoluteString;
                if([self downloadInfoOfTaskUrl:urlString]) {
                    if(downloadTask.state == NSURLSessionTaskStateSuspended) {
                        [downloadTask resume];
                    }//end if
                }//end if
            }//end for
        }];
    }//end for
}

- (void) suspendAllOnGoingDownloadTask {
    for(NSURLSession *session in sessions) {
        [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                NSString *urlString = downloadTask.originalRequest.URL.absoluteString;
                if([self downloadInfoOfTaskUrl:urlString]) {
                    if(downloadTask.state == NSURLSessionTaskStateRunning) {
                        [downloadTask suspend];
                    }//end if
                }//end if
            }//end for
        }];
    }//end for
}

- (double) elapsedSeconds {
    NSDate *now = [NSDate date];
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:startTime];
    return distanceBetweenDates;
}

- (int64_t) downloadRate {
    int64_t rate = numberOfBytesDownloadedSinceStart / [self elapsedSeconds];
    return rate;
}

- (BOOL) isDownloading {
    return !!sessions;
}

@end
