//
//  ObjectiveCDMDownload.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 23/5/14.
//
//

#import <Foundation/Foundation.h>

@interface ObjectiveCDMDownload : NSObject

@property (nonatomic, readonly, weak) NSURLSession *downloadSession;
@property (nonatomic, readonly) NSMutableURLRequest *request;

- (void) start;

@end
