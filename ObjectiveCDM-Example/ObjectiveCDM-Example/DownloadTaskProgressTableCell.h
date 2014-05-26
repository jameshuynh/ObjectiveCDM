//
//  DownloadTaskProgressTableCell.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 25/5/14.
//
//

#import <UIKit/UIKit.h>
#import "ObjectiveCDMDownloadTask.h"

@interface DownloadTaskProgressTableCell : UITableViewCell {
    UIProgressView* individualProgress;
    UILabel *downloadUrlLabel;
    UILabel *progressLabel;
    UILabel *fileNameLabel;
}
- (void) displayProgressForDownloadTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo;
@end
