//
//  DownloadViewController.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import <UIKit/UIKit.h>
#import "ObjectiveCDM.h"
#import "Reachability.h"

@interface DownloadViewController : UIViewController <ObjectiveCDMUIDelegate> {
    NSMutableArray *downloadLogs;
    UITextView *downloadLogsView;
    Reachability *internetReachability;
}

@property(nonatomic, retain) ObjectiveCDM* objectiveCDM;

@end
