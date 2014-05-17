//
//  ObjectiveCDM.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import <Foundation/Foundation.h>
#import "ObjectiveCDMDownloadBatch.h"

@interface ObjectiveCDM : NSObject

+ (instancetype) sharedInstance;
- (void) downloadBatch:(NSArray *)arrayOfDownloadInformation;
- (void) downloadURL:(NSString *)urlString to:(NSString *)destination;
- (void) startADownloadBatch:(ObjectiveCDMDownloadBatch *)batch;
@end
