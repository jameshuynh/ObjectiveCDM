//
//  SingleFileDownloadTestCase.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 1/6/14.
//
//

#import <XCTest/XCTest.h>
#import "ObjectiveCDM.h"
#import <SenTestingKit/SenTestingKit.h>

@interface SingleFileDownloadTestCase : XCTestCase <ObjectiveCDMDataDelegate, ObjectiveCDMUIDelegate> {
    BOOL didFinishOnDownloadTaskUICheck;
    BOOL didFinishDownloadTaskCheck;
    BOOL didFinishAllCheck;
    NSArray *smallFileBatch;
    NSArray *bigFileBatch;
}

@end

@implementation SingleFileDownloadTestCase

- (void) setUp {
    [super setUp];
    didFinishOnDownloadTaskUICheck = NO;
    didFinishDownloadTaskCheck = NO;
    didFinishAllCheck = NO;
    smallFileBatch = @[@{
        @"url": @"https://archive.org/download/BreakbeatSamplePack1-8zip/BreakPack5.zip",
        @"destination": @"test/BreakPack5.zip",
        @"fileSize": [NSNumber numberWithLongLong:5366561],
        @"checksum": @"4b18f3bbe5d0b7b6aa6b44e11ecaf303d442a7e5",
        @"identifier": @"Content-1004",
        @"progress": @0,
        @"completed": @NO
    }];
    
    bigFileBatch = @[@{
        @"url": @"http://87.76.16.10/test10.zip",
        @"destination": @"test/test10.zip",
        @"fileSize": [NSNumber numberWithLongLong:11536384],
        @"checksum": @"5e8bbbb38d137432ce0c8029da83e52e635c7a4f",
        @"identifier": @"Content-1001"
    }];
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testDownloadSmallFileWithOneConnection {
    ObjectiveCDM *objectiveCDM = [ObjectiveCDM sharedInstance];
    [objectiveCDM setNumberOfConcurrentThreads:1];
    objectiveCDM.dataDelegate = self;
    objectiveCDM.uiDelegate = self;
    [objectiveCDM addBatch:smallFileBatch];
    [objectiveCDM startDownloadingCurrentBatch];
    
    STAssertTrue([self waitForCompletion:30.0], @"Failed to get any results in time");
    STAssertTrue(didFinishAllCheck, @"didFinishAll is not called");
    STAssertTrue(didFinishOnDownloadTaskUICheck, @"didFinishOnDownloadTaskUICheck is not called");
    STAssertTrue(didFinishDownloadTaskCheck, @"didFinishDownloadTask is not called");
}

- (void) testDownloadSmallFileWithThreeConnections {
    ObjectiveCDM *objectiveCDM = [ObjectiveCDM sharedInstance];
    [objectiveCDM setNumberOfConcurrentThreads:3];
    objectiveCDM.dataDelegate = self;
    objectiveCDM.uiDelegate = self;
    [objectiveCDM addBatch:smallFileBatch];
    [objectiveCDM startDownloadingCurrentBatch];
    
    STAssertTrue([self waitForCompletion:30.0], @"Failed to get any results in time");
    STAssertTrue(didFinishAllCheck, @"didFinishAll is not called");
    STAssertTrue(didFinishOnDownloadTaskUICheck, @"didFinishOnDownloadTaskUICheck is not called");
    STAssertTrue(didFinishDownloadTaskCheck, @"didFinishDownloadTask is not called");
}

- (void) testDownloadBigFileWithThreeConnections {
    ObjectiveCDM *objectiveCDM = [ObjectiveCDM sharedInstance];
    [objectiveCDM setNumberOfConcurrentThreads:3];
    objectiveCDM.dataDelegate = self;
    objectiveCDM.uiDelegate = self;
    [objectiveCDM addBatch:bigFileBatch];
    [objectiveCDM startDownloadingCurrentBatch];
    
    STAssertTrue([self waitForCompletion:120.0], @"Failed to get any results in time");
    STAssertFalse(didFinishAllCheck, @"didFinishAll is not called");
    STAssertFalse(didFinishOnDownloadTaskUICheck, @"didFinishOnDownloadTaskUICheck is not called");
    STAssertFalse(didFinishDownloadTaskCheck, @"didFinishDownloadTask is not called");
}

- (void) failWithException:(NSException *)exception {
    NSLog(@"failed with exception");
}

- (void) didFinishOnDownloadTaskUI:(ObjectiveCDMDownloadTask *) downloadTask {
    didFinishOnDownloadTaskUICheck = YES;
}

- (void) didFinishDownloadTask:(ObjectiveCDMDownloadTask *)downloadInfo {
    didFinishDownloadTaskCheck = YES;
}

- (void)didFinishAll {
    didFinishAllCheck = YES;
}

- (void)didReachProgress:(float)progress {
    
}

- (void)didReachIndividualProgress:(float)progress onDownloadTask:(ObjectiveCDMDownloadTask *)task {
    
}

- (void) didHitDownloadErrorOnTask:(ObjectiveCDMDownloadTask *)task {
    
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!didFinishAllCheck);
    
    return didFinishAllCheck;
}

@end
