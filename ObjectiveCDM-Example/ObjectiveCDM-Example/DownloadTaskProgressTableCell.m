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
        downloadUrlLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width - 20, 20)];
        [downloadUrlLabel setFont:[UIFont systemFontOfSize:12]];
        individualProgress.frame = CGRectMake(10, 30, self.frame.size.width - 20, 11);
        [self.contentView addSubview:downloadUrlLabel];
        [self.contentView addSubview:individualProgress];
        
    }
    return self;
}

- (void)displayProgressForDownloadTask:(NSDictionary *)downloadTaskInfo {
    [downloadUrlLabel setText:downloadTaskInfo[@"url"]];
    individualProgress.progress = [(NSNumber *)downloadTaskInfo[@"progress"] floatValue];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    // [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
