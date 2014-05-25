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

@interface DownloadViewController : UIViewController <ObjectiveCDMUIDelegate, ObjectiveCDMDataDelegate, UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *downloadLogs;
    UITextView *downloadLogsView;
    Reachability *internetReachability;
    UILabel *overallProgressLabel;
    UITableView *individualProgressViewsContainer;
    UIProgressView *overallProgressBar;
    NSArray *downloadTaskInfos;
}

@property(nonatomic, retain) ObjectiveCDM* objectiveCDM;

@end
