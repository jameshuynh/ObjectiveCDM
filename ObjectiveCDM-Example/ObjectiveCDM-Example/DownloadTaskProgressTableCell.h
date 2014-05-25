//
//  DownloadTaskProgressTableCell.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 25/5/14.
//
//

#import <UIKit/UIKit.h>

@interface DownloadTaskProgressTableCell : UITableViewCell {
    UIProgressView* individualProgress;
    UILabel *downloadUrlLabel;
}
- (void) displayProgressForDownloadTask:(NSDictionary *)downloadTaskInfo;
@end
