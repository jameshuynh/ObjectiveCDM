//
//  DownloadViewController.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import "DownloadViewController.h"
#import <QuartzCore/QuartzCore.h>
@interface DownloadViewController ()

@end

@implementation DownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        downloadLogs = [[NSMutableArray alloc] initWithArray:@[]];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UILabel *progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 80)];
    DEBUG_VIEW(progressLabel);
    
    downloadLogsView = [[UITextView alloc] initWithFrame:CGRectMake(0, 135, 320, 120)];
    downloadLogsView.editable = NO;
    DEBUG_VIEW(downloadLogsView);
    
    [downloadLogsView setTextColor:[UIColor blackColor]];
    
    [progressLabel setTextAlignment:NSTextAlignmentCenter];
    [progressLabel setText:@"0.00%"];
    [progressLabel setTextColor:[UIColor blackColor]];
    [progressLabel setFont:[UIFont boldSystemFontOfSize:20]];
    progressLabel.tag = 1001;
    [self.view addSubview:progressLabel];
    [self.view addSubview:downloadLogsView];
    _objectiveCDM = [ObjectiveCDM sharedInstance];
    
    
    // [objectiveCDM downloadBatch:@[@{@"url": @"http://87.76.16.10/test10.zip", @"destination": @"test/test10.zip", @"checksum": @"5e8bbbb38d137432ce0c8029da83e52e635c7a4f"}]];
    _objectiveCDM.uiDelegate = self;
    [_objectiveCDM setTotalBytes:232821382];
    [_objectiveCDM setInitialDownloadedBytes:116410691];
    [self downloadManyFilesTest];
    
    // Do any additional setup after loading the view.
}

- (void) downloadManyFilesTest {
    [_objectiveCDM downloadBatch:@[
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

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didReachProgress:(float)progress {
    UILabel *label = (UILabel *)[self.view viewWithTag:1001];
    float percentage = progress * 100.0;
    NSString* formattedPercentage = [NSString stringWithFormat:@"%.02f%%", percentage];
    [label setText:formattedPercentage];
}

- (void) didFinish {
    UILabel *label = (UILabel *)[self.view viewWithTag:1001];
    [label setText:@"COMPLETED!"];
}

- (void) didHitDownloadErrorOnTask:(ObjectiveCDMDownloadTask* ) task {
    NSString *errorDescription = [task fullErrorDescription];
    [downloadLogs addObject:errorDescription];
    [downloadLogsView setText:[downloadLogs componentsJoinedByString:@"\n"]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
