### ObjectiveCDM: A Dead Simple Download Manager

ObjectiveCDM is a download manager built on top of NSURLSession for iOS.

Choose ObjectiveCDM for your next project as your download manager!

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries 

#### Podfile

```ruby
platform :ios, '7.0'
pod "ObjectiveCDM", "~> 1.0.0"
```

### Usage

#### ObjectiveCDM
`ObjectiveCDM` can perform download on a batch of URL strings or `NSURL` objects.

- Only URL and Destination are compulsory in each of the dowloading information.
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
        @"checksum": @"5e8bbbb38d137432ce0c8029da83e52e635c7a4f"
    },
    @{
        @"url": @"http://speedtest.dal01.softlayer.com/downloads/test100.zip",
        @"destination": @"test/test100.zip",
        @"fileSize": [NSNumber numberWithLongLong:104874307],
        @"checksum": @"592b849861f8d5d9d75bda5d739421d88e264900"
    }
]];
  
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
- (void) didFinishDownloadObject:(ObjectiveCDMDownloadTask *)downloadInfo {
  // this method is run on background thread
  // finish a task with ObjectiveCDMDownloadTask downloadInfo
}

```
