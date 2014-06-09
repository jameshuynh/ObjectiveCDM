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

@interface DownloadViewController : UIViewController <ObjectiveCDMUIDelegate, ObjectiveCDMDataDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
    NSMutableArray *downloadLogs;
    UITextView *downloadLogsView;
    Reachability *internetReachability;
    UILabel *overallProgressLabel;
    UILabel *overallRateLabel;
    UITableView *individualProgressViewsContainer;
    UIProgressView *overallProgressBar;
    NSArray *downloadTaskInfos;
    NSArray *objectiveCDMDownloadingTasks;
    NSTimer *downloadRateTimer;
    NSString *currentDownloadRate;
    NSString *currentInputURL;
}

@property(nonatomic, retain) ObjectiveCDM* objectiveCDM;

@end
