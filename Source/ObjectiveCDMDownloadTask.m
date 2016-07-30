//
//  ObjectiveCDMDownloadTask.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import "ObjectiveCDMDownloadTask.h"

@implementation ObjectiveCDMDownloadTask

- (instancetype) initWithURLString:(NSString *)urlString
                   withDestination:(NSString *)destination
     andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                       andChecksum:(NSString *)checksum
              andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput {
    self = [super init];
    if(self) {
        [self commonInstructor:urlString
               withDestination:destination
 andTotalBytesExpectedToWrite:totalBytesExpectedToWriteInput
                   andChecksum:checksum
          andFileHashAlgorithm:fileHashAlgorithmInput];
        self.url = [[NSURL alloc] initWithString:urlString];
    }//end if
    return self;
}

- (instancetype) initWithURL:(NSURL *)url
             withDestination:(NSString *)destination
andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                 andChecksum:(NSString *)checksum
        andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput {
    self = [super init];
    if(self) {
        [self commonInstructor:[url absoluteString]
               withDestination:destination
 andTotalBytesExpectedToWrite:totalBytesExpectedToWriteInput
                   andChecksum:checksum
          andFileHashAlgorithm:fileHashAlgorithmInput];
        self.url = url;
    }
    
    return self;
}

- (void) commonInstructor:(NSString *)urlString
          withDestination:(NSString *)destination
andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWriteInput
              andChecksum:(NSString *)checksum
     andFileHashAlgorithm:(FileHashAlgorithm)algorithm {
    self.completed = NO;
    self.totalBytesWritten = 0;
    self.totalBytesExpectedToWrite = totalBytesExpectedToWriteInput;
    self.urlString = urlString;
    self.checkSum = checksum;
    fileHashAlgorithm = algorithm;
   
    
    self.destination = destination;
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
    NSString *containerFolderPath = [[self absoluteDestinationPath] stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![[NSFileManager defaultManager] fileExistsAtPath:containerFolderPath]){
        NSError* createDirectoryError;
        if([fileManager createDirectoryAtPath:containerFolderPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError]) {
        }//end if
        if(createDirectoryError) {
            NSLog(@"Create Directory Error: %@", [createDirectoryError localizedDescription]);
        }//end if

    }//end if
    
    if([fileManager fileExistsAtPath:[self absoluteDestinationPath]] == YES) {
        // file exist at destination -> verify if this file has been downloaded before
        if([self verifyDownload]) {
            self.cachedProgress = 1;
            // retain file - this task has been completed
        } else {
            [self cleanUp];
        }//end else
    } else {
        [self cleanUp];
    }//end else
}

- (BOOL) verifyDownload {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // file does not exist as expected location
    if([fileManager fileExistsAtPath:[self absoluteDestinationPath]] == NO) {
        return NO;
    }//end if
    
    BOOL isVerified = NO;
    if(self.checkSum) {
        NSString *calculatedChecksum = [self retrieveChecksumOfDownloadedFile];
        isVerified = [calculatedChecksum isEqualToString:self.checkSum];
    } else { // check for file size
        NSError *attributesError;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[self absoluteDestinationPath] error:&attributesError];
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        int64_t fileSize = [fileSizeNumber longLongValue];
        isVerified = (fileSize == self.totalBytesExpectedToWrite);
    }
    if(isVerified) {
        self.completed = YES;
    }//end if
    if(self.completed) {
        self.totalBytesWritten = self.totalBytesExpectedToWrite;
    }//end if
    return isVerified;
}

- (NSString *) retrieveChecksumOfDownloadedFile {
    NSString *absoluteDestinationPath = [self absoluteDestinationPath];
    if(fileHashAlgorithm == FileHashAlgorithmMD5) {
        return [FileHash md5HashOfFileAtPath:absoluteDestinationPath];
    } else if(fileHashAlgorithm == FileHashAlgorithmSHA1) {
        return [FileHash sha1HashOfFileAtPath:absoluteDestinationPath];
    } else if(fileHashAlgorithm == FileHashAlgorithmSHA1) {
        return [FileHash sha512HashOfFileAtPath:absoluteDestinationPath];
    }//end else
    
    return nil;
}

- (void) cleanUp {
    self.completed = NO;
    self.error = nil;
    self.totalBytesWritten = 0;
    [self deleteDestinationFile];
}

- (void) cleanUpWithResumableData:(NSData *)data {
    self.completed = NO;
    self.totalBytesWritten = data.length;
    [self deleteDestinationFile];
    self.error = nil;
}

- (void) deleteDestinationFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *removeFileError;
    NSString *absoluteDestinationPath = [self absoluteDestinationPath];
    if([fileManager fileExistsAtPath:absoluteDestinationPath]) {
        [fileManager removeItemAtPath:absoluteDestinationPath error:&removeFileError];
    }//end if
    if(removeFileError) {
        NSLog(@"Removing Existing File Error: %@", [removeFileError localizedDescription]);
    }//end if
}

- (BOOL) isHittingErrorBecauseOffline {
    if(self.error) {
        return [self.lastErrorMessage rangeOfString:[NSString stringWithFormat:@"(Code %ld)", NSURLErrorNotConnectedToInternet]].location != NSNotFound || [self.lastErrorMessage rangeOfString:[NSString stringWithFormat:@"(Code %ld)", NSURLErrorNetworkConnectionLost]].location != NSNotFound;
    } else {
        return NO;
    }
}

- (BOOL) isHittingErrorConnectingToServer {
    if(self.lastErrorMessage) {
        return [self.lastErrorMessage rangeOfString:[NSString stringWithFormat:@"(Code %ld)", NSURLErrorRedirectToNonExistentLocation]].location != NSNotFound \
            || [self.lastErrorMessage rangeOfString:[NSString stringWithFormat:@"(Code %ld)", NSURLErrorBadServerResponse]].location != NSNotFound \
            || [self.lastErrorMessage rangeOfString:[NSString stringWithFormat:@"(Code %ld)", NSURLErrorZeroByteResource]].location != NSNotFound \
            || [self.lastErrorMessage rangeOfString:[NSString stringWithFormat:@"(Code %ld)", NSURLErrorTimedOut]].location != NSNotFound;
    } else {
        return NO;
    }//end else
}

- (void) captureReceivedError:(NSError *)error {
    self.error = error;
    self.lastErrorMessage = [self fullErrorDescription];
}

- (NSString *) fullErrorDescription {
    if(self.error) {
        int errorCode = (int)[self.error code];
        return [NSString stringWithFormat:@"Downloading URL %@ failed because of error: %@ (Code %d)", self.urlString, [self.error localizedDescription], errorCode];
    } else {
        return @"No Error";
    }//end else
}

// this is to counter iOS8 issue where the simulator will change the document directory every time we
// launch new simulator
- (NSString *) absoluteDestinationPath {
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%@", documentDirectory, self.destination];
}


@end
