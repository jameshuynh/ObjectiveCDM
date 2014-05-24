//
//  ObjectiveCDMDownloadBatch.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import <Foundation/Foundation.h>

@interface ObjectiveCDMDownloadBatch : NSObject {
    NSMutableArray *downloadInputs;
    NSMutableArray *urls;
}

@property(nonatomic, assign) BOOL isCompleted;

- (void) addTaskWithURL:(NSURL *)url andDestination:(NSString *)destination;
- (void) addTaskWithURLString:(NSString *)urlString andDestination:(NSString *)destination;
- (void) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL;
- (NSArray *)downloadObjects;
- (NSMutableDictionary *)downloadInfoOfTaskUrl:(NSString *)url;
- (void) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten;
- (void) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask;
- (NSDictionary *) totalBytesWrittenAndReceived;
- (void)startDownloadURL:(NSMutableDictionary *) downloadInput withURLSession:(NSURLSession *)session ;
@end
