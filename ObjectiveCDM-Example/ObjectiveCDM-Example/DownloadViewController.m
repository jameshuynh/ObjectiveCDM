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
                @"progress": @0,
                @"completed": @NO
            }],
            [[NSMutableDictionary alloc] initWithDictionary:@{
                @"url": @"http://www.colorado.edu/conflict/peace/download/peace.zip",
                @"destination": @"test/peace.zip",
                @"fileSize": [NSNumber numberWithLongLong:627874],
                @"checksum": @"0c0fe2686a45b3607dbb47690eadb89065341e95",
                @"identifier": @"Content-1002",
                @"progress": @0,
                @"completed": @NO
            }],
            [[NSMutableDictionary alloc] initWithDictionary:@{
                @"url": @"http://www.colorado.edu/conflict/peace/download/peace_problem.ZIP",
                @"destination": @"test/peace_problem.zip",
                @"fileSize": [NSNumber numberWithLongLong:294093],
                @"checksum": @"d742448fd7c9a17e879441a29a4b32c4a928b9cf",
                @"identifier": @"Content-1003",
                @"progress": @0,
                @"completed": @NO
            }],
            [[NSMutableDictionary alloc] initWithDictionary:@{
                @"url": @"https://archive.org/download/BreakbeatSamplePack1-8zip/BreakPack5.zip",
                @"destination": @"test/BreakPack5.zip",
                @"fileSize": [NSNumber numberWithLongLong:5366561],
                @"checksum": @"4b18f3bbe5d0b7b6aa6b44e11ecaf303d442a7e5",
                @"identifier": @"Content-1004",
                @"progress": @0,
                @"completed": @NO
            }],
            [[NSMutableDictionary alloc] initWithDictionary:@{
                @"url": @"http://speedtest.dal01.softlayer.com/downloads/test100.zip",
                @"destination": @"test/test100.zip",
                @"fileSize": [NSNumber numberWithLongLong:104874307],
                @"checksum": @"592b849861f8d5d9d75bda5d739421d88e264900",
                @"identifier": @"Content-1005",
                @"progress": @0,
                @"completed": @NO
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
    overallProgressBar.progress = 0;
    [overallProgressBar setTransform:CGAffineTransformMakeScale(1.0, 3.0)];
    
    [self.view addSubview:overallProgressLabel];
    [self.view addSubview:overallProgressBar];
    
}

- (void) setupIndividualProgressView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    individualProgressViewsContainer = [[UITableView alloc] initWithFrame:CGRectMake(0, 165, screenWidth, 300)];
    individualProgressViewsContainer.dataSource = self;
    individualProgressViewsContainer.delegate = self;
    [self.view addSubview:individualProgressViewsContainer];
    [individualProgressViewsContainer reloadData];
    individualProgressViewsContainer.contentSize = CGSizeMake(screenWidth, [downloadTaskInfos count] * 65);
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
    // [self setupLogView];
    self.navigationItem.title = @"Batch Download";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(downloadManyFilesTest:)];
    _objectiveCDM = [ObjectiveCDM sharedInstance];
    _objectiveCDM.uiDelegate = self;
    _objectiveCDM.dataDelegate = self;
    
    // if you want to set total bytes and initial downloaded bytes
    // [_objectiveCDM setTotalBytes:232821382];
    // [_objectiveCDM setInitialDownloadedBytes:116410691];
}

- (void) downloadManyFilesTest:(UIBarButtonItem *)startButton {
    UIApplication* app = [UIApplication sharedApplication];
    if([[startButton title] isEqualToString:@"Resume"]) {
        [_objectiveCDM continueInCompletedDownloads];
        [startButton setTitle:@"Stop"];
        app.networkActivityIndicatorVisible = YES;
    } else if([[startButton title] isEqualToString:@"Start"]) {
        [_objectiveCDM downloadBatch:downloadTaskInfos];
        [startButton setTitle:@"Stop"];
        app.networkActivityIndicatorVisible = YES;
    } else if([[startButton title] isEqualToString:@"Stop"]) {
        [_objectiveCDM suspendAllOnGoingDownloads];
        [startButton setTitle:@"Resume"];
        app.networkActivityIndicatorVisible = NO;
    }
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
    [overallProgressBar setProgress:progress animated:NO];
}

- (void) didFinishAll {
    [overallProgressLabel setText:@"COMPLETED!"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) didFinishOnDownloadTaskUI:(ObjectiveCDMDownloadTask *) downloadTask {
    NSMutableDictionary *downloadTaskInfo = downloadTaskInfos[downloadTask.position];
    downloadTaskInfo[@"completed"] = @YES;
    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:downloadTask.position inSection:0];
    [individualProgressViewsContainer reloadRowsAtIndexPaths:@[rowToReload] withRowAnimation:UITableViewRowAnimationNone];
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

- (void) didFinishDownloadTask:(ObjectiveCDMDownloadTask *)downloadInfo {
    // do anything with ObjectiveCDMDownloadTask instance
}

# pragma UITableView DataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65;
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
