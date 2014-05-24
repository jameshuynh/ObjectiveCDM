//
//  DownloadViewController.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import "DownloadViewController.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UILabel *progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 80)];
    [progressLabel setTextAlignment:NSTextAlignmentCenter];
    [progressLabel setText:@"0%"];
    [progressLabel setTextColor:[UIColor blackColor]];
    [progressLabel setFont:[UIFont boldSystemFontOfSize:20]];
    progressLabel.tag = 1001;
    [self.view addSubview:progressLabel];
    ObjectiveCDM* objectiveCDM = [ObjectiveCDM sharedInstance];
    //    [objectiveCDM downloadBatch:@[
    //        @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/228/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8398&contentId=228", @"destination":@"test/test.zip"},
    //        @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/230/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8399&contentId=230", @"destination": @"test/test1.zip"},
    //        @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/233/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8400&contentId=233", @"destination": @"test/test2.zip"},
    //        @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/234/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8401&contentId=234", @"destination": @"test/test3.zip"},
    //        @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/235/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8403&contentId=236", @"destination": @"test/test4.zip"},
    //        @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/200/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8403&contentId=200", @"destination": @"test/test5.zip"}
    //    ]];
    
    //    [objectiveCDM downloadBatch:@[
    //      @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/228/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8398&contentId=228", @"destination":@"test/test1.zip"},
    //      @{@"url": @"http://fedexlivenlearn.projectwebby.com/storage/activity_module_content_zips/241/download?auth_token=9CYZFmppU33JYm138ZLG&activityId=8343&contentId=241", @"destination":@"test/test2.zip"}]];
    
    // [objectiveCDM downloadBatch:@[@{@"url": @"http://casie.projectwebby.com/system/intro_videos/uploaded_videos/000/000/006/original/starhub-low-latency-customer-facing-video-v7-cut-down-2.mp4", @"destination": @"test/video.mp4"}]];
    // [objectiveCDM downloadBatch:@[@{@"url": @"http://speedtest.dal01.softlayer.com/downloads/test100.zip", @"destination": @"test/test.zip"}, @{@"url": @"http://87.76.16.10/test10.zip", @"destination": @"test/test2.zip"}, @{@"url": @"http://mia.futurehosting.com/test.zip", @"destination": @"test/test3.zip"}]];
    
    [objectiveCDM downloadBatch:@[@{@"url": @"http://87.76.16.10/test10.zip", @"destination": @"test/test10.zip"}, @{@"url": @"http://casie.projectwebby.com/system/intro_videos/uploaded_videos/000/000/006/original/starhub-low-latency-customer-facing-video-v7-cut-down-2.mp4", @"destination": @"test/video-v7-cut-down-2.mp4"}]];
    objectiveCDM.uiDelegate = self;
    
    // Do any additional setup after loading the view.
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

- (BOOL) didFinish {
    return YES;
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
