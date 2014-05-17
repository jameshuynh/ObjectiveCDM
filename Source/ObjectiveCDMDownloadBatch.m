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
        operationQueue = [[JGOperationQueue alloc] init];
        operationQueue.handleNetworkActivityIndicator = YES;
        operationQueue.handleBackgroundTask = YES;
    }//end if
    return self;
}

- (void) addTaskWithURL:(NSURL *)url andDestination:(NSString *)destination {
    if([self isTaskExistWithURL:url andDestination:destination] == NO) {
        [self createFolderForDestination:destination];
        NSDictionary *task = @{@"url": url, @"destination": destination};
        [downloadInputs addObject:task];
    }//end if
}

- (void) addTaskWithURLString:(NSString *)urlString andDestination:(NSString *)destination {
    NSURL *url = [NSURL URLWithString:urlString];
    if([self isTaskExistWithURL:url andDestination:destination] == NO) {
        [self createFolderForDestination:destination];
        NSDictionary *task = @{@"url": url, @"destination": destination};
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

- (void)createFolderForDestination:(NSString *)destination {
    NSString *containerFolderPath = [destination stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:containerFolderPath]){
        NSError* error;
        if([[NSFileManager defaultManager] createDirectoryAtPath:containerFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        }//end if
    }
}

- (void) start {
    for(NSDictionary *dictionary in downloadInputs) {
        NSLog(@"destintaion %@ & url = %@", dictionary[@"destination"], dictionary[@"url"] );
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:dictionary[@"url"]];
        //customize the request if needed... Example:
        [request setTimeoutInterval:90.0];

        JGDownloadOperation *operation = [[JGDownloadOperation alloc] initWithRequest:request destinationPath:dictionary[@"destination"] allowResume:YES];
        [operation setMaximumNumberOfConnections:6];
        [operation setRetryCount:3];
        
        __block CFTimeInterval started;
        
        [operation setCompletionBlockWithSuccess:^(JGDownloadOperation *operation) {
            double kbLength = (double)operation.contentLength/1024.0f;
            CFTimeInterval delta = CFAbsoluteTimeGetCurrent()-started;
            NSLog(@"Success! Downloading %.2f MB took %.1f seconds, average Speed: %.2f kb/s", kbLength/1024.0f, delta, kbLength/delta);
        } failure:^(JGDownloadOperation *operation, NSError *error) {
            NSLog(@"Operation Failed: %@", error.localizedDescription);
        }];
        
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, unsigned long long totalBytesReadThisSession, unsigned long long totalBytesWritten, unsigned long long totalBytesExpectedToRead, NSUInteger tag) {
            CFTimeInterval delta = CFAbsoluteTimeGetCurrent()-started;
            NSLog(@"Progress: %.2f%% Average Speed: %.2f kB/s", ((double)totalBytesWritten/(double)totalBytesExpectedToRead)*100.0f, totalBytesReadThisSession/1024.0f/delta);
        }];
        
        [operation setOperationStartedBlock:^(NSUInteger tag, unsigned long long totalBytesExpectedToRead) {
            started = CFAbsoluteTimeGetCurrent();
        }];
        
        [operationQueue addOperation:operation];
    }
    
}

@end
