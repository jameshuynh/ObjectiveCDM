### ObjectiveCDM: A Dead Simple Download Manager

ObjectiveCDM is a download manager built on top of NSURLSession for iOS. It supports auto resume on internet connection recover. 

Choose ObjectiveCDM for your next project as your download manager!

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries 

#### Podfile

```ruby
platform :ios, '7.0'
pod "ObjectiveCDM", "~> 1.0.0"
```

### Features

- Ability to download a batch of files.
- Checksum (MD5, SHA1, SHA512) / File Size is verified once a file has been downloaded. Redownload file if checksum / file size is mismatched.
- Auto resume on internet connection recovery.
- Overall Progress & individual download progress

### Usage

#### ObjectiveCDM
`ObjectiveCDM` can perform download on a batch of URL strings or `NSURL` objects.

- Only URL and Destination are compulsory in each of the dowloading information. `url` can be string or `NSURL` object
- If `fileSize` is not supplied, the download manager will trigger a `HEAD` request to query for content length to fill in `fileSize`.
- If checksum is supplied, the download manager will verify againsts the downloaded file's checksum. If no checksum is supplied, the verification will be only based on the `fileSize`. Default file hashing algorithm is SHA1. You can change by using

```objective-c
ObjectiveCDM* objectiveCDM = [ObjectiveCDM sharedInstance];
objectiveCDM.fileHashAlgorithm = FileHashAlgorithmMD5;
```

- If the final verification on downloaded file is failed, the file will be queued to be downloaded again.

```objective-c
#import "ObjectiveCDM.h"

[objectiveCDM downloadBatch:@[
    @{
        @"url": @"http://87.76.16.10/test10.zip",
        @"destination": @"test/test10.zip",
        @"fileSize": [NSNumber numberWithLongLong:11536384],
        @"checksum": @"5e8bbbb38d137432ce0c8029da83e52e635c7a4f",
        @"identifier": @"Content-1001"
    },
    @{
        @"url": @"http://speedtest.dal01.softlayer.com/downloads/test100.zip",
        @"destination": @"test/test100.zip",
        @"fileSize": [NSNumber numberWithLongLong:104874307],
        @"checksum": @"592b849861f8d5d9d75bda5d739421d88e264900",
        @"identifier": @"Content-1002"
    }
]];
  
```

#### ObjectiveCDM

- You can set initial downloaded bytes - this will help to calculate the overall progress if you have already have some downloaded files from last download

```objective-c
ObjectiveCDM* objectiveCDM = [ObjectiveCDM sharedInstance];
[objectiveCDM setInitialDownloadedBytes:1024];
```

- You can set total bytes for helping to calculate the overall progress. This total byte will override the calculation of the actual total bytes to be received of each download.

```objective-c
ObjectiveCDM* objectiveCDM = [ObjectiveCDM sharedInstance];
[objectiveCDM setTotalBytes:1048576];
```

- By default, the checksum algorithm to verify the downloaded file is SHA1. You can change this by using

``` objective-c
ObjectiveCDM* objectiveCDM = [ObjectiveCDM sharedInstance];
objectiveCDM.fileHashAlgorithm = FileHashAlgorithmMD5;
// objectiveCDM.fileHashAlgorithm = FileHashAlgorithmSHA512;
// objectiveCDM.fileHashAlgorithm = FileHashAlgorithmSHA1; // default
```

#### ObjectiveCDMUIDelegate

`ObjectiveCDMUIDelegate` can be used to update progress of the batch download and update finish status of the whole batch

```objective-c
// ObjectiveCDM* objectiveCDM = [ObjectiveCDM sharedInstance];
// objectiveCDM.uiDelegate = self;
// ...
- (void) didReachProgress:(float)progress {
  // this method is run on main thread
  // ... update progress bar or progress text here
}

- (void) didFinish {
  // this method is also run on main thread
  // ... update completed status of the whole batch
}
```

#### ObjectiveCDMDataDelegate

`ObjectiveCDMDataDelegate` can be used to process file after finish downloading

```objective-c
// ObjectiveCDM* objectiveCDM = [ObjectiveCDM sharedInstance];
// objectiveCDM.dataDelegate = self;
// ...
- (void) didFinishDownloadObject:(ObjectiveCDMDownloadTask *)downloadTaskInfo {
  // this method is run on background thread
  // finish a task with ObjectiveCDMDownloadTask downloadInfo
}

```

#### ObjectiveCDMDownloadTask

In `didFinishDownloadObject` you will receive an `ObjectiveCDMDownloadTask` instance. Inside this instance, you will be able to retrieve the following attributes

```objective-c
NSURL *url = downloadTaskInfo.url;
NSString *urlString = downloadTaskInfo.urlString;
NSString *destination = downloadTaskInfo.destination; // destination is the full path to the downloaded file
NSString *fileName = downloadTaskInfo.fileName;
NSString *checksum = downloadTaskInfo.checksum;
NSString *identifier = downloadTaskInfo.identifier;
```

### Contribution

Contribution and Suggestion is very much appreciated :). Please fork and send your pull request!

### Roadmap

- Auto Test Coverage
- Split download (i.e. download 1 file using many threads) to speed up download

### License

ObjectiveCDM is available under the MIT license. See the LICENSE file for more info.