//
//  AppDelegate.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 15/5/14.
//
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
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
    
    NSLog(@"result of equal ==> %d", [@"https://dl.dropboxusercontent.com/u/2857188/BGTransferDemo.zip" isEqualToString:@"https://dl.dropboxusercontent.com/u/2857188/BGTransferDemo.zip"]);
    [objectiveCDM downloadBatch:@[@{@"url": @"http://87.76.16.10/test10.zip", @"destination": @"test/test10.zip"}]];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
