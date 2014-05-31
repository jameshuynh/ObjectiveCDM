//
//  ObjectiveCDMDownloadTask.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import "ObjectiveCDMDownloadTask.h"
#include <string.h>

void concatenateFiles(char *filesPath[], char *resultFilePath, int numberOfParts) {
    int index = 0;
    FILE *inputFile;
    int bufferSize = 8192;
    int bytesRead;
    char buffer[bufferSize];
    FILE *resultFile;
    
    remove(resultFilePath);
    resultFile = fopen(resultFilePath, "wb");
    for(index = 0; index < numberOfParts; index++) {
        char* inputFilePath = filesPath[index];
        inputFile = fopen(inputFilePath, "rb");
        while((bytesRead = fread(buffer, 1, bufferSize, inputFile))) {
            fwrite(buffer, 1, bytesRead, resultFile);
        }//end while
        fclose(inputFile);
    }
    fclose(resultFile);
}


@implementation ObjectiveCDMDownloadTask

- (instancetype) initWithURLString:(NSString *)urlString
                   withDestination:(NSString *)destination
     andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                       andChecksum:(NSString *)checksum
              andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput
            andNumberOfConnections:(int)numberOfConnectionsInput {
    self = [super init];
    if(self) {
        [self commonInstructor:urlString
               withDestination:destination
 andTotalBytesExepectedToWrite:totalBytesExpectedToWriteInput
                   andChecksum:checksum
          andFileHashAlgorithm:fileHashAlgorithmInput
         andNumberOfConnections:numberOfConnectionsInput];
        self.url = [[NSURL alloc] initWithString:urlString];
        self.totalBytesExpectedToWrite = totalBytesExpectedToWriteInput;
    }//end if
    return self;
}

- (instancetype) initWithURL:(NSURL *)url
             withDestination:(NSString *)destination
andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                 andChecksum:(NSString *)checksum
        andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput
      andNumberOfConnections:(int)numberOfConnectionsInput {
    self = [super init];
    if(self) {
        [self commonInstructor:[url absoluteString]
               withDestination:destination
 andTotalBytesExepectedToWrite:totalBytesExpectedToWriteInput
                   andChecksum:checksum
          andFileHashAlgorithm:fileHashAlgorithmInput
         andNumberOfConnections:numberOfConnectionsInput];
        self.url = url;
    }
    
    return self;
}

- (void) commonInstructor:(NSString *)urlString
          withDestination:(NSString *)destination
andTotalBytesExepectedToWrite:(int64_t)totalBytesExpectedToWriteInput
              andChecksum:(NSString *)checksum
     andFileHashAlgorithm:(FileHashAlgorithm)algorithm
   andNumberOfConnections:(int)numberOfConnectionsInput {
    self.completed = NO;
    
    
    self.totalBytesExpectedToWrite = totalBytesExpectedToWriteInput;
    self.urlString = urlString;
    self.checkSum = checksum;
    self.isDownloading = NO;
    fileHashAlgorithm = algorithm;
    numberOfConnections = numberOfConnectionsInput;
    // [self resetBytesWrittenArray];
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.destination = [NSString stringWithFormat:@"%@/%@", documentDirectory, destination];
    self.fileName = [self.destination lastPathComponent];
    [self prepareFolderForDestination];
}

- (void) resetBytesWrittenArray {
    NSMutableArray *bytesWrittenArray = [[NSMutableArray alloc] init];
    for(int i = 0; i < numberOfConnections; i++) {
        [bytesWrittenArray addObject:@0];
    }//end for
    self.totalBytesWrittenArray = bytesWrittenArray;
    
}

- (float) downloadingProgress {
    if(self.totalBytesExpectedToWrite > 0) {
        return (double)self.totalBytesWritten / (double)self.totalBytesExpectedToWrite;
    } else {
        return 0;
    }
}

- (int64_t) totalBytesWritten {
    if(self.completed) {
        return self.totalBytesExpectedToWrite;
    }//end if
    
    int64_t total = 0;
    
    for(NSNumber *bytesWritten in [self totalBytesWrittenArray] ) {
        total += [bytesWritten longLongValue];
    }
    // NSLog(@"totalBytesWrittenArray %@", self.totalBytesWrittenArray);
    // NSLog(@"total for %@ = %lld", self.urlString, total);
    
    return total;
}

- (void) prepareFolderForDestination {
    NSString *containerFolderPath = [self.destination stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![[NSFileManager defaultManager] fileExistsAtPath:containerFolderPath]){
        NSError* createDirectoryError;
        if([fileManager createDirectoryAtPath:containerFolderPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError]) {
        }//end if
        if(createDirectoryError) {
            NSLog(@"Create Directory Error: %@", [createDirectoryError localizedDescription]);
        }//end if

    }//end if
    
    if([fileManager fileExistsAtPath:self.destination] == YES) {
        // file exist at destination -> verify if this file has been downloaded before
        if([self mergeAndVerifyDownload]) {
            self.cachedProgress = 1;
            // retain file - this task has been completed
        } else {
            [self cleanUp];
        }//end else
    } else {
        [self cleanUp];
    }//end else
}

- (void) mergeDownloadedParts {
    
    char **filesPath = (char **) malloc(sizeof(char*) * (numberOfConnections + 1));
    int index = 0;
    for(index = 0; index < numberOfConnections; index++) {
        
        NSString *s = [NSString stringWithFormat:@"%@.part%d", self.destination, index];
        const char *cstr = [s cStringUsingEncoding:NSUTF8StringEncoding];//get cstring
        int len = strlen(cstr);//get its length
        char *cStringCopy = (char *) malloc(sizeof(char) * (len + 1));//allocate memory, + 1 for ending '\0'
        strcpy(cStringCopy, cstr);//make a copy
        filesPath[index] = cStringCopy;//put the point in cargs
    }//end for
    filesPath[index] = NULL;
    char *resultFilePath = (char *)[self.destination UTF8String];
    
    concatenateFiles(filesPath, resultFilePath, numberOfConnections);
    for(index = 0; index < numberOfConnections; index++) {
        free(filesPath[index]);
    }//end for
    free(filesPath);
    [self removeFileParts];
}

- (void) removeFileParts {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(int index = 0; index < numberOfConnections; index++) {
        NSError *error;
        NSString *partPath = [NSString stringWithFormat:@"%@.part%d", self.destination, index];
        if([fileManager fileExistsAtPath:partPath]) {
            [fileManager removeItemAtPath:partPath error:&error];
        }
    }
}

- (BOOL) mergeAndVerifyDownload {
    [self mergeDownloadedParts];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // file does not exist as expected location
    if([fileManager fileExistsAtPath:self.destination] == NO) {
        return NO;
    }//end if
    
    BOOL isVerified = NO;
    if(self.checkSum) {
        NSString *calculatedChecksum = [self retrieveChecksumOfDownloadedFile];
        isVerified = [calculatedChecksum isEqualToString:self.checkSum];
    } else { // check for file size
        NSError *attributesError;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:self.destination error:&attributesError];
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        int64_t fileSize = [fileSizeNumber longLongValue];
        isVerified = (fileSize == self.totalBytesExpectedToWrite);
    }
    if(isVerified) {
        self.completed = YES;
    }//end if
    return isVerified;
}

- (NSString *) retrieveChecksumOfDownloadedFile {
    if(fileHashAlgorithm == FileHashAlgorithmMD5) {
        return [FileHash md5HashOfFileAtPath:self.destination];
    } else if(fileHashAlgorithm == FileHashAlgorithmSHA1) {
        return [FileHash sha1HashOfFileAtPath:self.destination];
    } else if(fileHashAlgorithm == FileHashAlgorithmSHA1) {
        return [FileHash sha512HashOfFileAtPath:self.destination];
    }//end else
    
    return nil;
}

- (BOOL) checkDownloadCompleted {
    return self.totalBytesWritten == self.totalBytesExpectedToWrite;
}

- (void) cleanUp {
    self.completed = NO;
    self.error = nil;
    [self resetBytesWrittenArray];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *removeFileError;
    if([fileManager fileExistsAtPath:self.destination]) {
        [fileManager removeItemAtPath:self.destination error:&removeFileError];
    }//end if
    for(int index = 0; index < numberOfConnections; index++) {
        NSString *partDestination = [NSString stringWithFormat:@"%@.part-%d", self.destination, index];
        if([fileManager fileExistsAtPath:partDestination]) {
            [fileManager removeItemAtPath:partDestination error:&removeFileError];
        }//end if
    }
    if(removeFileError) {
        NSLog(@"Removing Existing File Error: %@", [removeFileError localizedDescription]);
    }//end if
}

- (BOOL) isHittingErrorBecauseOffline {
    if(self.error) {
        return self.error.code == -1009;
    } else {
        return NO;
    }
}

- (BOOL) isHittingErrorConnectingToServer {
    if(self.error) {
        return (self.error.code == -1004 || [[self.error description] isEqualToString:@"Could not connect to the server."]);
    } else {
        return NO;
    }//end else
}

- (NSString *) fullErrorDescription {
    if(self.error) {
        int errorCode = (int)[self.error code];
        return [NSString stringWithFormat:@"Downloading URL %@ failed because of error: %@ (Code %d)", self.urlString, [self.error localizedDescription], errorCode];
        return @"";
    } else {
        return @"No Error";
    }//end else
}

- (void)setBytesWrittenForDownloadPart:(int)partNumber withNumberOfBytes:(int64_t)bytesWritten {
    NSLog(@"bytes written %lld - part %d", bytesWritten, partNumber);
    self.totalBytesWrittenArray[partNumber] = [NSNumber numberWithLongLong:bytesWritten];
}

@end
