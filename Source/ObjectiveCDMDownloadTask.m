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
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.destination = [NSString stringWithFormat:@"%@/%@", documentDirectory, destination];
    self.fileName = [self.destination lastPathComponent];
    [self prepare];
}

- (void) prepare {
    if([self verifyMergedFile]) {
        self.cachedProgress = 1;
    } else {
        int64_t totalVerifiedDownloadedBytes = [self captureTotalBytesDownloadedInFileParts];
        if(totalVerifiedDownloadedBytes == self.totalBytesExpectedToWrite) {
            // has downloaded all parts
            BOOL result = [self mergeAndVerifyDownload];
            if(result) {
                self.cachedProgress = 1;
            } else {
                [self prepareDestinationFolderAndCleanUp];
            }//end else
        } else if(totalVerifiedDownloadedBytes > 0) {
            self.cachedProgress = totalVerifiedDownloadedBytes * 1.0 / self.totalBytesExpectedToWrite;
        } else {
            [self prepareDestinationFolderAndCleanUp];
        }//end else
    }//end else
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
    
    NSArray *bytesWrittenArrayCopy;
    @synchronized(self.totalBytesWrittenArray) {
        bytesWrittenArrayCopy = [[self totalBytesWrittenArray] copy];
        for(NSNumber *bytesWritten in bytesWrittenArrayCopy ) {
            total += [bytesWritten longLongValue];
        }//end for
        return total;
    }
}

- (void) prepareDestinationFolderAndCleanUp {
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
    [self cleanUp];

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
    return [self verifyMergedFile];
}

/*
 * If any file part that does not have the supposed file size of that part
 * this function will return 0 so the whole parts can be purged out
 */
- (int64_t) captureTotalBytesDownloadedInFileParts {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int totalVerifiedBytes = 0;
    [self resetBytesWrittenArray];
    for(int index = 0; index < numberOfConnections; index++) {
        NSString *partDestination = [self destinationOfPart:index];
        if([fileManager fileExistsAtPath:partDestination]) {
            int64_t supposedFileSizeOfPart = [self supposedFileSizeOfPart:index];
            int64_t actualFileSizeOfFileAtPart = [self fileSizeOfFileAtPath:partDestination];
            
            // invalid file part -> return 0 immediately
            if(supposedFileSizeOfPart != actualFileSizeOfFileAtPart) {
                return 0;
            } else {
                totalVerifiedBytes += supposedFileSizeOfPart;
                @synchronized(self.totalBytesWrittenArray) {
                    self.totalBytesWrittenArray[index] = [NSNumber numberWithLongLong:supposedFileSizeOfPart];
                }
            }//end else
        }//end if
    }//end for
    return totalVerifiedBytes;
}

- (BOOL) verifyMergedFile {
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
        isVerified = ([self fileSizeOfFileAtPath:self.destination] == self.totalBytesExpectedToWrite);
    }//end else
    
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
    if(removeFileError) {
        NSLog(@"Removing Existing File Error: %@", [removeFileError localizedDescription]);
    }//end if
    [self removeFileParts];
}

- (void)setBytesWrittenForDownloadPart:(int)partNumber withNumberOfBytes:(int64_t)bytesWritten {
    @synchronized(self.totalBytesWrittenArray) {
        [self.totalBytesWrittenArray replaceObjectAtIndex:partNumber withObject:[NSNumber numberWithLongLong:bytesWritten]];
    }
}

# pragma Part Information
/*
 * part will be numbered as part0, part1, part2, ... part(n-1)
 * first n - 1 parts will have file size: self.totalBytesExpectedToWrite / numberOfConnections
 * last part will have the remaining size
 */
- (int64_t) supposedFileSizeOfPart:(int) partNumber {
    if(numberOfConnections == 1) {
        return self.totalBytesExpectedToWrite;
    }//end if
    
    int64_t perSessionBytesCount = self.totalBytesExpectedToWrite / numberOfConnections;
    if(partNumber == numberOfConnections - 1) {
        return self.totalBytesExpectedToWrite - (perSessionBytesCount * (numberOfConnections - 1));
    } else {
        return perSessionBytesCount;
    }//end else
}

- (NSString *) rangeOfPart:(int) partNumber {
    NSString *range = @"bytes=";
    int64_t perSessionBytesCount = self.totalBytesExpectedToWrite / numberOfConnections;
    range = [range stringByAppendingString:[[NSNumber numberWithLongLong:(perSessionBytesCount * partNumber)] stringValue]];
    range = [range stringByAppendingString:@"-"];
    if(partNumber != numberOfConnections - 1) {
        range = [range stringByAppendingString:[NSString stringWithFormat:@"%lld", (perSessionBytesCount * (partNumber + 1)) - 1]];
    }//end if
    return range;
}

- (NSString *) destinationOfPart:(int) partNumber {
    return [NSString stringWithFormat:@"%@.part%d", self.destination, partNumber];
}

- (BOOL) alreadyDownloadedPart:(int)partNumber {
    @synchronized(self.totalBytesWrittenArray) {
        return [self.totalBytesWrittenArray[partNumber] longLongValue] > 0;
    }
}

# pragma Merge Downloaded Part(s)

- (void) mergeDownloadedParts {
    if(numberOfConnections == 1) {
        [self moveTheOnlyDownloadedPartToDestination];
    }//end if
    else {
        [self mergeDownloadedMoreThanOneDownloadedParts];
    }
}

- (void) moveTheOnlyDownloadedPartToDestination {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *partPath = [self destinationOfPart:0];
    
    NSError *movingFileError;
    if([fileManager fileExistsAtPath:partPath]) {
        [fileManager moveItemAtPath:partPath toPath:self.destination error:&movingFileError];
    }//end if
}

- (void) mergeDownloadedMoreThanOneDownloadedParts {
    char **filesPath = (char **) malloc(sizeof(char*) * (numberOfConnections + 1));
    int partNumber = 0;
    for(partNumber = 0; partNumber < numberOfConnections; partNumber++) {
        filesPath[partNumber] = [self convertNSStringToCString:[self destinationOfPart:partNumber]];
    }//end for
    filesPath[partNumber] = NULL;
    char *resultFilePath = [self convertNSStringToCString:self.destination];
    
    concatenateFiles(filesPath, resultFilePath, numberOfConnections);
    for(partNumber = 0; partNumber < numberOfConnections; partNumber++) {
        free(filesPath[partNumber]);
    }//end for
    free(filesPath);
    free(resultFilePath);
    [self removeFileParts];
}

# pragma Error Handling

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

# pragma Utility

- (int64_t) fileSizeOfFileAtPath:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *attributesError;
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:&attributesError];
    if(attributesError) {
        return -1;
    }//end if
    
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    return [fileSizeNumber longLongValue];
}

/*
 * This function is used to convert an Objective C NSString to a char* in C
 * Input: NSString
 * Output: C - char*
 */
- (char*) convertNSStringToCString:(NSString *)str {
    const char *cstr = [str cStringUsingEncoding:NSUTF8StringEncoding];//get cstring
    int len = (int)strlen(cstr);//get its length
    char *cStringCopy = (char *) malloc(sizeof(char) * (len + 1));//allocate memory, + 1 for ending '\0'
    strcpy(cStringCopy, cstr);//make a copy
    return cStringCopy;
}

@end
