//
//  ObjectiveCDM.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import <Foundation/Foundation.h>
#import "ObjectiveCDMDownloadBatch.h"

@protocol ObjectiveCDMUIDelegate;
@protocol ObjectiveCDMUIDataDelegate;

@interface ObjectiveCDM : NSObject <NSURLSessionDownloadDelegate> {
    NSURLSession *downloadSession;
    ObjectiveCDMDownloadBatch* currentBatch;
}

+ (instancetype) sharedInstance;
- (void) downloadBatch:(NSArray *)arrayOfDownloadInformation;
- (void) downloadURL:(NSString *)urlString to:(NSString *)destination;
- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch;

@property(nonatomic, retain) id<ObjectiveCDMUIDelegate> uiDelegate;
@property(nonatomic, retain) id<ObjectiveCDMUIDataDelegate> dataDelegate;

@end

@protocol ObjectiveCDMUIDelegate
- (void) didReachProgress:(float)progress;
- (BOOL) didFinish;
@end

@protocol ObjectiveCDMUIDataDelegate
- (void) didFinishDownloadObject:(NSDictionary *)downloadInfo;
@end