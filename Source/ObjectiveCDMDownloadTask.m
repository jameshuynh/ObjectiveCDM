//
//  ObjectiveCDMDownloadTask.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import "ObjectiveCDMDownloadTask.h"

@implementation ObjectiveCDMDownloadTask

- (instancetype) initWithURLString:(NSString *)urlString withDestination:(NSString *)destination andChecksum:(NSString *)checksum {
    self = [super init];
    if(self) {
        [self commonInstructor:urlString withDestination:destination andChecksum:checksum];
        self.url = [[NSURL alloc] initWithString:urlString];
    }//end if
    return self;
}

- (instancetype) initWithURL:(NSURL *)url withDestination:(NSString *)destination andChecksum:(NSString *)checksum {
    self = [super init];
    if(self) {
        [self commonInstructor:[url absoluteString] withDestination:destination andChecksum:checksum];
        self.url = url;
    }
    
    return self;
}

- (void) commonInstructor:(NSString *)urlString withDestination:(NSString *)destination andChecksum:(NSString *)checksum {
    self.completed = NO;
    self.totalBytesWritten = 0;
    self.totalBytesExpectedToWrite = 0;
    self.urlString = urlString;
    self.checkSum = checksum;
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.destination = [NSString stringWithFormat:@"%@/%@", documentDirectory, destination];
    self.fileName = [self.destination lastPathComponent];
    [self prepareFolderForDestination];
}

- (float) downloadingProgress {
    if(self.totalBytesExpectedToWrite > 0) {
        return (double)self.totalBytesWritten / (double)self.totalBytesExpectedToWrite;
    } else {
        return 0;
    }
}

- (void) prepareFolderForDestination {
    NSString *containerFolderPath = [self.destination stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![[NSFileManager defaultManager] fileExistsAtPath:containerFolderPath]){
        NSError* createDirectoryError;
        if([[NSFileManager defaultManager] createDirectoryAtPath:containerFolderPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError]) {
        }//end if
        if(createDirectoryError) {
            NSLog(@"Create Directory Error: %@", [createDirectoryError localizedDescription]);
        }//end if

    }//end if
    
    NSError *removeFileError;
    if([fileManager fileExistsAtPath:self.destination]) {
        [fileManager removeItemAtPath:self.destination error:&removeFileError];
    }//end if
    if(removeFileError) {
        NSLog(@"Removing Existing File Error: %@", [removeFileError localizedDescription]);
    }//end if
}

@end
