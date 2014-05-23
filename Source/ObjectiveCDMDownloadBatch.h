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
    NSMutableArray *downloadingProgresses;
    
}

- (void) addTaskWithURL:(NSURL *)url andDestination:(NSString *)destination;
- (void) addTaskWithURLString:(NSString *)urlString andDestination:(NSString *)destination;
- (void)handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL;
- (NSArray *)downloadObjects;
- (NSDictionary *)downloadInfoOfTaskUrl:(NSString *)url;
- (void)updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage;
@end
