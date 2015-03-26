//
//  ObjectiveCDMDownloadTask.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import <Foundation/Foundation.h>
#import "ObjectiveCDM.h"
#import "FileHash.h"

@interface ObjectiveCDMDownloadTask : NSObject {
    FileHashAlgorithm fileHashAlgorithm;
}

@property(nonatomic, assign) float cachedProgress;
@property(nonatomic, assign) BOOL completed;
@property(nonatomic, assign) int64_t totalBytesWritten;
@property(nonatomic, assign) int64_t totalBytesExpectedToWrite;

@property(nonatomic, assign) NSUInteger position;
@property(nonatomic, retain) NSURL* url;
@property(nonatomic, retain) NSString* urlString;
@property(nonatomic, retain) NSString* destination;
@property(nonatomic, retain) NSString* fileName;
@property(nonatomic, retain) NSString* checkSum;
@property(nonatomic, retain) NSError* error;
@property(nonatomic, retain) NSString* lastErrorMessage;
@property(nonatomic, retain) NSString* identifier;

- (instancetype) initWithURLString:(NSString *)urlString
                 withDestination:(NSString *)destination
                 andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
                 andChecksum:(NSString *)checksum
                 andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput;

- (instancetype) initWithURL:(NSURL *)url
                 withDestination:(NSString *)destination
                 andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
                 andChecksum:(NSString *)checksum
                 andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput;

- (void) cleanUp;
- (void) cleanUpWithResumableData:(NSData *)data;
- (float) downloadingProgress;
- (BOOL) verifyDownload;
- (NSString *) fullErrorDescription;
- (BOOL) isHittingErrorBecauseOffline;
- (BOOL) isHittingErrorConnectingToServer;
- (void) captureReceivedError:(NSError *)error;
- (NSString *) absoluteDestinationPath;
@end
