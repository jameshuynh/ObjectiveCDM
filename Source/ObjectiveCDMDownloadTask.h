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
    int numberOfConnections;
}

@property(nonatomic, assign) float cachedProgress;
@property(nonatomic, assign) BOOL completed;
@property(nonatomic, assign) BOOL isDownloading;
@property(nonatomic, retain) NSMutableArray* totalBytesWrittenArray;
@property(nonatomic, assign) int64_t totalBytesExpectedToWrite;

@property(nonatomic, assign) NSUInteger position;
@property(nonatomic, retain) NSURL* url;
@property(nonatomic, retain) NSString* urlString;
@property(nonatomic, retain) NSString* destination;
@property(nonatomic, retain) NSString* fileName;
@property(nonatomic, retain) NSString* checkSum;
@property(nonatomic, retain) NSError* error;
@property(nonatomic, retain) NSString* identifier;

- (instancetype) initWithURLString:(NSString *)urlString
                 withDestination:(NSString *)destination
                 andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWrite
                 andChecksum:(NSString *)checksum
                 andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput
                 andNumberOfConnections:(int)numberOfConnectionsInput;

- (instancetype) initWithURL:(NSURL *)url
                 withDestination:(NSString *)destination
                 andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWrite
                 andChecksum:(NSString *)checksum
                 andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput
                 andNumberOfConnections:(int)numberOfConnectionsInput;

- (void) cleanUp;
- (float) downloadingProgress;
- (BOOL) mergeAndVerifyDownload;
- (BOOL) checkDownloadCompleted;
- (NSString *) fullErrorDescription;
- (BOOL) isHittingErrorBecauseOffline;
- (BOOL) isHittingErrorConnectingToServer;
- (int64_t) totalBytesWritten;
- (void)setBytesWrittenForDownloadPart:(int)partNumber withNumberOfBytes:(int64_t)bytesWritten;

@end
