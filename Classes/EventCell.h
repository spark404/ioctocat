#import <UIKit/UIKit.h>


@protocol EventCellDelegate
- (void)openEventItem:(id)theEventItem;
@end


@class GHEvent;

@interface EventCell : UITableViewCell {
	GHEvent *event;
	id<EventCellDelegate> delegate;
  @private
	IBOutlet UIView *actionsView;
	IBOutlet UILabel *dateLabel;
	IBOutlet UILabel *titleLabel;
	IBOutlet UIImageView *iconView;
	IBOutlet UIImageView *gravatarView;
	IBOutlet UIImageView *detailBackgroundView;
	IBOutlet UIButton *repositoryButton;
	IBOutlet UIButton *otherRepositoryButton;
	IBOutlet UIButton *userButton;
	IBOutlet UIButton *otherUserButton;
	IBOutlet UIButton *organizationButton;
	IBOutlet UIButton *issueButton;
	IBOutlet UIButton *commitButton;
	IBOutlet UIButton *gistButton;
}

@property(nonatomic,retain)GHEvent *event;
@property(assign)id<EventCellDelegate> delegate;

- (void)markAsNew;
- (void)markAsRead;
- (void)showDetails;
- (void)hideDetails;
- (IBAction)showRepository:(id)sender;
- (IBAction)showOtherRepository:(id)sender;
- (IBAction)showUser:(id)sender;
- (IBAction)showOtherUser:(id)sender;
- (IBAction)showOrganization:(id)sender;
- (IBAction)showIssue:(id)sender;
- (IBAction)showCommit:(id)sender;
- (IBAction)showGist:(id)sender;

@end
