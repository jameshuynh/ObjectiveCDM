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
    });
    return sharedManager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.objectiveCDM"];
        downloadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
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
    NSString *downloadURL = [[[downloadTask originalRequest] URL] absoluteString];
    [currentBatch updateProgressOfDownloadURL:downloadURL withProgress:(totalBytesWritten * 1.0 / totalBytesExpectedToWrite)];
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

- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch {
    currentBatch = batch;
    for(NSDictionary *dictionary in batch.downloadObjects) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:dictionary[@"url"]];
        //customize the request if needed... Example:
        [request setTimeoutInterval:90.0];
        NSURLSessionDownloadTask *downloadTask = [downloadSession downloadTaskWithRequest:request];
        [downloadTask resume];
    }

}

@end
