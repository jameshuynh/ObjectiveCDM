//
//  DownloadViewController.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import "DownloadViewController.h"
#import "DownloadTaskProgressTableCell.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        downloadLogs = [[NSMutableArray alloc] initWithArray:@[]];
        downloadTaskInfos = @[
          [[NSMutableDictionary alloc] initWithDictionary:@{
             @"url": @"http://87.76.16.10/test10.zip",
             @"destination": @"test/test10.zip",
             @"fileSize": [NSNumber numberWithLongLong:11536384],
             @"checksum": @"5e8bbbb38d137432ce0c8029da83e52e635c7a4f",
             @"identifier": @"Content-1001",
             @"progress": @0
          }],
          [[NSMutableDictionary alloc] initWithDictionary:@{
             @"url": @"http://speedtest.dal01.softlayer.com/downloads/test100.zip",
             @"destination": @"test/test100.zip",
             @"fileSize": [NSNumber numberWithLongLong:104874307],
             @"checksum": @"592b849861f8d5d9d75bda5d739421d88e264900",
             @"identifier": @"Content-1002",
             @"progress": @0
          }]
         ];

    }
    return self;
}

- (void) setUpOverallProgressView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    overallProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, screenWidth, 40)];
    [overallProgressLabel setTextAlignment:NSTextAlignmentCenter];
    [overallProgressLabel setText:@"0.00%"];
    [overallProgressLabel setTextColor:[UIColor blackColor]];
    [overallProgressLabel setFont:[UIFont boldSystemFontOfSize:20]];
    overallProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    overallProgressBar.frame = CGRectMake(80, 120, screenWidth - 160, 30);
    [overallProgressBar setTransform:CGAffineTransformMakeScale(1.0, 3.0)];
    
    [self.view addSubview:overallProgressLabel];
    [self.view addSubview:overallProgressBar];
    
}

- (void) setupIndividualProgressView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    individualProgressViewsContainer = [[UITableView alloc] initWithFrame:CGRectMake(0, 165, screenWidth, 200)];
    individualProgressViewsContainer.dataSource = self;
    [self.view addSubview:individualProgressViewsContainer];
    [individualProgressViewsContainer reloadData];
    individualProgressViewsContainer.contentSize = CGSizeMake(screenWidth, [downloadTaskInfos count] * 45);
    [individualProgressViewsContainer setSeparatorInset:UIEdgeInsetsZero];
}

- (void) setupLogView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    downloadLogsView = [[UITextView alloc] initWithFrame:CGRectMake(0, 365, screenWidth, 120)];
    downloadLogsView.editable = NO;
    [downloadLogsView setTextColor:[UIColor blackColor]];
    [self.view addSubview:downloadLogsView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setUpOverallProgressView];
    [self setupIndividualProgressView];
    [self setupLogView];
    
    _objectiveCDM = [ObjectiveCDM sharedInstance];
    _objectiveCDM.uiDelegate = self;
    _objectiveCDM.dataDelegate = self;
    [_objectiveCDM setTotalBytes:232821382];
    [_objectiveCDM setInitialDownloadedBytes:116410691];
    [self downloadManyFilesTest];
}

- (void) downloadManyFilesTest {
    [_objectiveCDM downloadBatch:downloadTaskInfos];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma ObjectiveCDMUIDelagate

- (void) didReachProgress:(float)progress {
    float percentage = progress * 100.0;
    NSString* formattedPercentage = [NSString stringWithFormat:@"%.02f%%", percentage];
    [overallProgressLabel setText:formattedPercentage];
    overallProgressBar.progress = progress;
}

- (void) didFinishAll {
    [overallProgressLabel setText:@"COMPLETED!"];
}

- (void) didHitDownloadErrorOnTask:(ObjectiveCDMDownloadTask* ) task {
    NSString *errorDescription = [task fullErrorDescription];
    [downloadLogs addObject:errorDescription];
    [downloadLogsView setText:[downloadLogs componentsJoinedByString:@"\n"]];
}

- (void) didReachIndividualProgress:(float)progress onDownloadTask:(ObjectiveCDMDownloadTask* )downloadTask {
    NSMutableDictionary *downloadTaskInfo = downloadTaskInfos[downloadTask.position];
    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:downloadTask.position inSection:0];
    downloadTaskInfo[@"progress"] = [NSNumber numberWithFloat:progress];
    [individualProgressViewsContainer reloadRowsAtIndexPaths:@[rowToReload] withRowAnimation:UITableViewRowAnimationNone];
}

# pragma ObjectiveCDMDataDelegate

- (void) didFinishDownloadObject:(ObjectiveCDMDownloadTask *)downloadInfo {
    // do anything with ObjectiveCDMDownloadTask instance
}

# pragma UITableView DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [downloadTaskInfos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"IndividualProgressViewCell";
    DownloadTaskProgressTableCell *progressViewCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!progressViewCell) {
        progressViewCell = [[DownloadTaskProgressTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }//end if
    [progressViewCell displayProgressForDownloadTask:downloadTaskInfos[indexPath.row]];
    
    return progressViewCell;
    
}
@end
