//
//  DownloadTaskProgressTableCell.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 25/5/14.
//
//

#import "DownloadTaskProgressTableCell.h"

@implementation DownloadTaskProgressTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        individualProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        downloadUrlLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, self.frame.size.width - 20, 20)];
        [downloadUrlLabel setFont:[UIFont systemFontOfSize:12]];
        individualProgress.frame = CGRectMake(10, 30, self.frame.size.width - 20, 11);
        progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 42, self.frame.size.width - 20, 15)];
        [progressLabel setFont:[UIFont systemFontOfSize:12]];
        [progressLabel setTextColor:[UIColor grayColor]];
        [self.contentView addSubview:downloadUrlLabel];
        [self.contentView addSubview:individualProgress];
        [self.contentView addSubview:progressLabel];
        
    }
    return self;
}

- (void)displayProgressForDownloadTask:(NSDictionary *)downloadTaskInfo {
    [downloadUrlLabel setText:downloadTaskInfo[@"url"]];
    individualProgress.progress = [(NSNumber *)downloadTaskInfo[@"progress"] floatValue];
    NSNumber *progress = (NSNumber *)downloadTaskInfo[@"progress"];
    NSString *status = @"";
    // NSLog(@"download task info %@", downloadTaskInfo);
    if([downloadTaskInfo[@"completed"] boolValue] == YES) {
        status = @"(Completed)";
    }//end if
    [progressLabel setText:[NSString stringWithFormat:@"%.2f%% %@", [progress floatValue] * 100, status]];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    // [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
