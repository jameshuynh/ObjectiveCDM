//
//  ObjectiveCDMDownloadBatch.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import <Foundation/Foundation.h>
#import "JGOperationQueue.h"
#import "JGDownloadDefines.h"

@interface ObjectiveCDMDownloadBatch : NSObject {
    JGOperationQueue* operationQueue;
    NSMutableArray *downloadInputs;
    
}

- (void) addTaskWithURL:(NSURL *)url andDestination:(NSString *)destination;
- (void) addTaskWithURLString:(NSString *)urlString andDestination:(NSString *)destination;
- (void) start;
@end
