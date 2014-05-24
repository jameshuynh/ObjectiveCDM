//
//  ObjectiveCDMDownloadBatch.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import "ObjectiveCDMDownloadBatch.h"

@implementation ObjectiveCDMDownloadBatch

- (instancetype) init {
    self = [super init];
    if(self) {
        downloadInputs = [[NSMutableArray alloc] initWithArray:@[]];
        urls = [[NSMutableArray alloc] initWithArray:@[]];
    }//end if
    return self;
}

- (void) addTaskWithURL:(NSURL *)url andDestination:(NSString *)destination {
    if([self isTaskExistWithURL:url andDestination:destination] == NO) {
        [self createFolderForDestination:destination];
        NSMutableDictionary *task = [[NSMutableDictionary alloc] initWithDictionary:@{@"totalBytesDownloaded": @0, @"totalBytesToBeReceived": @0, @"url": url, @"destination": destination}];
        [urls addObject:[url absoluteString]];
        [downloadInputs addObject:task];
    }//end if
}

- (void) addTaskWithURLString:(NSString *)urlString andDestination:(NSString *)destination {
    NSURL *url = [NSURL URLWithString:urlString];
    if([self isTaskExistWithURL:url andDestination:destination] == NO) {
        [self createFolderForDestination:destination];
        NSMutableDictionary *task = [[NSMutableDictionary alloc] initWithDictionary:@{@"totalBytesDownloaded": @0, @"totalBytesToBeReceived": @0, @"url": url, @"destination": destination}];
        [urls addObject:urlString];
        [downloadInputs addObject:task];
    }//end if
}

- (BOOL) isTaskExistWithURL:(NSURL *)url andDestination:(NSString *)destination {
    for(NSDictionary *dictionary in downloadInputs) {
        if([[dictionary[@"url"] absoluteString] isEqualToString:[url absoluteString]] ||
           [dictionary[@"destination"] isEqualToString:destination]) {
            return YES;
        }
    }
    return NO;
}

- (void) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL {
    NSError *movingFileError;
    NSError *removingFileError;
    NSDictionary *downloadInfo = [self downloadInfoOfTaskUrl:downloadURL];
    NSString *destinationPath = downloadInfo[@"destination"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:destinationPath]) {
        [fileManager removeItemAtPath:destinationPath error:&removingFileError];
    }//end if
    
    [fileManager moveItemAtPath:downloadedFileLocation.path toPath:destinationPath error:&movingFileError];
    
    if(movingFileError) {
        NSLog(@"Error: %@", movingFileError.localizedDescription);
        // TODO: redownload file
    } else {
        // done
    }//end else
}

- (void) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    // task is already inside the session - do nothing
    NSURL *url = downloadTask.originalRequest.URL;
    NSMutableDictionary *downloadInfo = [self downloadInfoOfTaskUrl:url.absoluteString];
    downloadInfo[@"totalBytesDownloaded"] = [NSNumber numberWithLongLong:downloadTask.countOfBytesReceived];
    NSNumber *bytesToBeReceived = downloadInfo[@"totalBytesToBeReceived"];
    if([bytesToBeReceived longLongValue] == 0) {
        downloadInfo[@"totalBytesToBeReceived"] = [NSNumber numberWithLongLong:downloadTask.countOfBytesExpectedToReceive];
    }//end if
}

- (void) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten {
    [[self downloadInfoOfTaskUrl:url] setObject:[NSNumber numberWithLongLong:totalBytesWritten] forKey:@"totalBytesDownloaded"];
}

- (void) createFolderForDestination:(NSString *)destination {
    NSString *containerFolderPath = [destination stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:containerFolderPath]){
        NSError* error;
        if([[NSFileManager defaultManager] createDirectoryAtPath:containerFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        }//end if
    }
}

- (NSArray *)downloadObjects {
    return downloadInputs;
}

- (NSMutableDictionary *)downloadInfoOfTaskUrl:(NSString *)url {
    return downloadInputs[[urls indexOfObject:url]];
}

- (void)startDownloadURL:(NSMutableDictionary *) downloadInput withURLSession:(NSURLSession *)session {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadInput[@"url"]];
    if([downloadInput[@"totalBytesToBeReceived"] longLongValue] == 0) {
        [self requestForTotalBytesForURL:downloadInput[@"url"] withCallback:^(int64_t totalBytesToBeReceived)  {
            downloadInput[@"totalBytesToBeReceived"] = [NSNumber numberWithLongLong:totalBytesToBeReceived];
            [self downloadRequest:request inURLSession:session];
        }];
    } else {
        [self downloadRequest:request inURLSession:session];
    }//end else
}

- (void) downloadRequest:(NSMutableURLRequest *)request inURLSession:(NSURLSession *)session {
    [request setTimeoutInterval:90.0];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask resume];
}

- (void) requestForTotalBytesForURL:(NSURL *)url withCallback:(void (^)(int64_t))completed {
    NSMutableURLRequest *headRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [headRequest setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    [headRequest setHTTPMethod:@"HEAD"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *headTask = [session dataTaskWithRequest:headRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completed(response.expectedContentLength);
    }];
    [headTask resume];
}

- (NSDictionary *) totalBytesWrittenAndReceived {
    int64_t totalDownloadedBytes = 0;
    int64_t totalBytesExpectedToReceive = 0;
    for(NSDictionary *downloadObject in downloadInputs) {
        NSNumber *downloadedBytes = downloadObject[@"totalBytesDownloaded"];
        NSNumber *expectedBytes = downloadObject[@"totalBytesToBeReceived"];
        totalDownloadedBytes += [downloadedBytes longLongValue];
        totalBytesExpectedToReceive += [expectedBytes longLongValue];
    }
    
    return @{
        @"totalDownloadedBytes": [NSNumber numberWithLongLong:totalDownloadedBytes],
        @"totalToBeReceivedBytes": [NSNumber numberWithLongLong:totalBytesExpectedToReceive]
    };
}

@end
