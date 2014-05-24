//
//  ObjectiveCDMDownloadTask.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import <Foundation/Foundation.h>

@interface ObjectiveCDMDownloadTask : NSObject

@property(nonatomic, assign) BOOL completed;
@property(nonatomic, assign) int64_t totalBytesWritten;
@property(nonatomic, assign) int64_t totalBytesExpectedToWrite;

@property(nonatomic, retain) NSURL* url;
@property(nonatomic, retain) NSString* urlString;
@property(nonatomic, retain) NSString* destination;
@property(nonatomic, retain) NSString* fileName;
@property(nonatomic, retain) NSString* checkSum;

- (instancetype) initWithURLString:(NSString *)urlString withDestination:(NSString *)destination andChecksum:(NSString *)checksum;

- (instancetype) initWithURL:(NSURL *)url withDestination:(NSString *)destination andChecksum:(NSString *)checksum;

- (float) downloadingProgress;

@end
