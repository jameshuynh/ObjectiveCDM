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

- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch {
    [batch start];
}

@end
