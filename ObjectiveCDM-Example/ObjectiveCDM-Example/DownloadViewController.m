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
            @{
                @"url": @"http://87.76.16.10/test10.zip",
                @"destination": @"test/test10.zip",
                @"fileSize": [NSNumber numberWithLongLong:11536384],
                @"checksum": @"5e8bbbb38d137432ce0c8029da83e52e635c7a4f",
                @"identifier": @"Content-1001"
            }
//            , @{
//                @"url": @"http://www.colorado.edu/conflict/peace/download/peace.zip",
//                @"destination": @"test/peace.zip",
//                @"fileSize": [NSNumber numberWithLongLong:627874],
//                @"checksum": @"0c0fe2686a45b3607dbb47690eadb89065341e95",
//                @"identifier": @"Content-1002",
//                @"progress": @0,
//                @"completed": @NO
//            },
//            @{
//                @"url": @"http://www.colorado.edu/conflict/peace/download/peace_problem.ZIP",
//                @"destination": @"test/peace_problem.zip",
//                @"fileSize": [NSNumber numberWithLongLong:294093],
//                @"checksum": @"d742448fd7c9a17e879441a29a4b32c4a928b9cf",
//                @"identifier": @"Content-1003",
//                @"progress": @0,
//                @"completed": @NO
//            },
//            @{
//                @"url": @"https://archive.org/download/BreakbeatSamplePack1-8zip/BreakPack5.zip",
//                @"destination": @"test/BreakPack5.zip",
//                @"fileSize": [NSNumber numberWithLongLong:5366561],
//                @"checksum": @"4b18f3bbe5d0b7b6aa6b44e11ecaf303d442a7e5",
//                @"identifier": @"Content-1004",
//                @"progress": @0,
//                @"completed": @NO
//            },
//            @{
//                @"url": @"http://speedtest.dal01.softlayer.com/downloads/test100.zip",
//                @"destination": @"test/test100.zip",
//                @"fileSize": [NSNumber numberWithLongLong:104874307],
//                @"checksum": @"592b849861f8d5d9d75bda5d739421d88e264900",
//                @"identifier": @"Content-1005",
//                @"progress": @0,
//                @"completed": @NO
//            },
//            @{
//                @"url": @"http://www.colorado.edu/conflict/peace/download/peace_treatment.ZIP",
//                @"destination": @"test/peace_treatment.zip",
//                @"fileSize": [NSNumber numberWithLongLong:523193],
//                @"checksum": @"60180da39e4bf4d16bd453eb6f6c6d97082ac47a",
//                @"identifier": @"Content-1006",
//                @"progress": @0,
//                @"completed": @NO
//            }
        ];
    }
    return self;
}

- (void) setUpOverallProgressView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    overallProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, screenWidth, 40)];
    overallRateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 130, screenWidth, 20)];
    [overallProgressLabel setTextAlignment:NSTextAlignmentCenter];
    [overallProgressLabel setText:@"0.00%"];
    [overallProgressLabel setTextColor:[UIColor blackColor]];
    [overallProgressLabel setFont:[UIFont boldSystemFontOfSize:20]];
    
    [overallRateLabel setTextAlignment:NSTextAlignmentCenter];
    [overallRateLabel setText:@"0 KB/s"];
    [overallRateLabel setTextColor:[UIColor blackColor]];
    [overallRateLabel setFont:[UIFont boldSystemFontOfSize:12]];
    
    overallProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    overallProgressBar.frame = CGRectMake(80, 120, screenWidth - 160, 30);
    overallProgressBar.progress = 0;
    [overallProgressBar setTransform:CGAffineTransformMakeScale(1.0, 3.0)];
    
    [self.view addSubview:overallProgressLabel];
    [self.view addSubview:overallProgressBar];
    [self.view addSubview:overallRateLabel];
    
}

- (void) setupIndividualProgressView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    individualProgressViewsContainer = [[UITableView alloc] initWithFrame:CGRectMake(0, 165, screenWidth, screenHeight - 165)];
    individualProgressViewsContainer.dataSource = self;
    individualProgressViewsContainer.delegate = self;
    [self.view addSubview:individualProgressViewsContainer];
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
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd target: self action: @selector(addNewDownloadTask)];
    
    _objectiveCDM = [ObjectiveCDM sharedInstance];
    _objectiveCDM.uiDelegate = self;
    _objectiveCDM.dataDelegate = self;
    objectiveCDMDownloadingTasks = [_objectiveCDM addBatch:downloadTaskInfos];
    [individualProgressViewsContainer reloadData];
    // if you want to set total bytes and initial downloaded bytes
    // [_objectiveCDM setTotalBytes:232821382];
    // [_objectiveCDM setInitialDownloadedBytes:116410691];
}

- (void) addNewDownloadTask {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Download" message:@"Key in your URL:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    if(currentInputURL) {
        [[alertView textFieldAtIndex:0] setText:currentInputURL];
    }
    [alertView show];
}


- (void) downloadManyFilesTest:(UIBarButtonItem *)startButton {
    UIApplication* app = [UIApplication sharedApplication];
    if([[startButton title] isEqualToString:@"Resume"]) {
        [_objectiveCDM continueInCompletedDownloads];
        [startButton setTitle:@"Pause"];
        app.networkActivityIndicatorVisible = YES;
    } else if([[startButton title] isEqualToString:@"Start"]) {
        [_objectiveCDM startDownloadingCurrentBatch];
        [startButton setTitle:@"Pause"];
        downloadRateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateOverallRate) userInfo:nil repeats:YES];
        app.networkActivityIndicatorVisible = YES;
    } else if([[startButton title] isEqualToString:@"Stop"] || [[startButton title] isEqualToString:@"Pause"]) {
        [_objectiveCDM suspendAllOnGoingDownloads];
        [startButton setTitle:@"Resume"];
        app.networkActivityIndicatorVisible = NO;
    }
}

- (void) updateOverallRate {
    NSArray* downloadRateAndRemaining = [_objectiveCDM downloadRateAndRemainingTime];
    NSString *downloadRate = downloadRateAndRemaining[0];
    NSString *remainingTime = downloadRateAndRemaining[1];
    [overallRateLabel setText:[NSString stringWithFormat:@"%@ - Remaining %@", downloadRate, remainingTime]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) isValidURL:(NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

#pragma UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) { // OK Button
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *url = [textField text];
        if([self isValidURL:url]) {
            NSArray *parts = [url componentsSeparatedByString:@"/"];
            NSString *filename = [parts objectAtIndex:[parts count]-1];
            [[ObjectiveCDM sharedInstance] addDownloadTask:@{@"url": url, @"destination": [NSString stringWithFormat:@"test/%@", filename]}];
            objectiveCDMDownloadingTasks = [_objectiveCDM downloadingTasks];
            [individualProgressViewsContainer reloadData];

        }//end if
        else {
            currentInputURL = url;
            [self addNewDownloadTask];
        }
    } else {
        currentInputURL = nil;
    }
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
    [downloadRateTimer invalidate];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) didFinishOnDownloadTaskUI:(ObjectiveCDMDownloadTask *) downloadTask {
    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:downloadTask.position inSection:0];
    [individualProgressViewsContainer reloadRowsAtIndexPaths:@[rowToReload] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) didHitDownloadErrorOnTask:(ObjectiveCDMDownloadTask* ) task {
    NSString *errorDescription = [task fullErrorDescription];
    [downloadLogs addObject:errorDescription];
    [downloadLogsView setText:[downloadLogs componentsJoinedByString:@"\n"]];
}

- (void) didReachIndividualProgress:(float)progress onDownloadTask:(ObjectiveCDMDownloadTask* )downloadTask {
    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:downloadTask.position inSection:0];
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
    return [objectiveCDMDownloadingTasks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"IndividualProgressViewCell";
    DownloadTaskProgressTableCell *progressViewCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!progressViewCell) {
        progressViewCell = [[DownloadTaskProgressTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }//end if
    [progressViewCell displayProgressForDownloadTask:objectiveCDMDownloadingTasks[indexPath.row]];
    
    return progressViewCell;
    
}
@end
