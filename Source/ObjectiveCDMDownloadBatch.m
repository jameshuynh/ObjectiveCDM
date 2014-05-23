//
//  ObjectiveCDMDownloadBatch.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import "ObjectiveCDMDownloadBatch.h"

@implementation ObjectiveCDMDownloadBatch

- (instancetype) init {
    self = [super init];
    if(self) {
        downloadInputs = [[NSMutableArray alloc] initWithArray:@[]];
        urls = [[NSMutableArray alloc] initWithArray:@[]];
        downloadingProgresses = [[NSMutableArray alloc] initWithArray:@[]];
    }//end if
    return self;
}

- (void) addTaskWithURL:(NSURL *)url andDestination:(NSString *)destination {
    if([self isTaskExistWithURL:url andDestination:destination] == NO) {
        [self createFolderForDestination:destination];
        NSDictionary *task = @{@"url": url, @"destination": destination};
        [urls addObject:[url absoluteString]];
        [downloadingProgresses addObject:@0];
        [downloadInputs addObject:task];
    }//end if
}

- (void) addTaskWithURLString:(NSString *)urlString andDestination:(NSString *)destination {
    NSURL *url = [NSURL URLWithString:urlString];
    if([self isTaskExistWithURL:url andDestination:destination] == NO) {
        [self createFolderForDestination:destination];
        NSDictionary *task = @{@"url": url, @"destination": destination};
        [urls addObject:urlString];
        [downloadingProgresses addObject:@0];
        [downloadInputs addObject:task];
    }//end if
}

- (BOOL) isTaskExistWithURL:(NSURL *)url andDestination:(NSString *)destination {
    for(NSDictionary *dictionary in downloadInputs) {
        if([[dictionary[@"url"] absoluteString] isEqualToString:[url absoluteString]] ||
           [dictionary[@"destination"] isEqualToString:destination]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL {
    NSError *movingFileError;
    NSError *removingFileError;
    NSDictionary *downloadInfo = [self downloadInfoOfTaskUrl:downloadURL];
    NSString *destinationPath = downloadInfo[@"destination"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:destinationPath]) {
        [fileManager removeItemAtPath:destinationPath error:&removingFileError];
    }//end if
    
    [fileManager moveItemAtPath:downloadedFileLocation.path toPath:destinationPath error:&movingFileError];
    
    if(movingFileError) {
        NSLog(@"Error: %@", movingFileError.localizedDescription);
        // TODO: redownload file
    } else {
        // done
    }//end else
}

- (void)updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage {
    downloadingProgresses[[urls indexOfObject:url]] = [NSNumber numberWithFloat:percentage];
    NSLog(@"Downloading Progress %@", downloadingProgresses[[urls indexOfObject:url]]);
}

- (void)createFolderForDestination:(NSString *)destination {
    NSString *containerFolderPath = [destination stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:containerFolderPath]){
        NSError* error;
        if([[NSFileManager defaultManager] createDirectoryAtPath:containerFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        }//end if
    }
}

- (NSArray *)downloadObjects {
    return downloadInputs;
}

- (NSDictionary *)downloadInfoOfTaskUrl:(NSString *)url {
    return downloadInputs[[urls indexOfObject:url]];
}

@end
