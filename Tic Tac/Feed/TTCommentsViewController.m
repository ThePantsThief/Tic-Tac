//
//  TTCommentsViewController.m
//  Tic Tac
//
//  Created by Tanner on 4/21/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "TTCommentsViewController.h"
#import "TTCommentsHeaderView.h"
#import "TTCommentCell.h"
#import "TTReplyViewController.h"
#import "TTCensorshipControl.h"


@interface TTCommentsViewController () <TTCensorshipDelegate>
@property (nonatomic, readonly) TTCommentsHeaderView *commentsHeaderView;
@property (nonatomic, readonly) YYYak *yak;
@property (nonatomic, readonly) TTFeedArray<YYComment*> *dataSource;
@property (nonatomic, readonly) NSArray<YYComment*> *arrayToUse;
@end

@implementation TTCommentsViewController

+ (instancetype)commentsForYak:(YYYak *)yak {
    TTCommentsViewController *comments = [self new];
    comments->_yak = yak;
    return comments;
}

+ (instancetype)commentsForNotification:(YYNotification *)notification {
    TTCommentsViewController *comments = [self new];
    [[YYClient sharedClient] getYak:notification completion:^(YYYak *yak, NSError *error) {
        [comments displayOptionalError:error];
        if (!error) {
            comments->_yak = yak;
            [comments.commentsHeaderView updateWithYak:yak];
            
            if (comments.view.tag) {
                [comments reloadCommentSectionData];
            }
        } else {
            if (comments.view.tag) {
                [comments dismissAndNotifyYakRemoved];
            } else {
                comments.view.tag = 2;
            }
        }
    }];
    
    return comments;
}

- (void)dismissAndNotifyYakRemoved {
    [self.navigationController popViewControllerAnimated:YES];
    [[TBAlertController simpleOKAlertWithTitle:@"Yak Not Available" message:@"This yak has been removed."] show];
}

- (id)init {
    self = [super init];
    if (self) {
        _dataSource = [TTFeedArray new];
        _dataSource.sortNewestFirst = YES;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    _commentsHeaderView = [TTCommentsHeaderView headerForYak:self.yak];
    self.tableView.tableHeaderView = self.commentsHeaderView;
    [self.commentsHeaderView.addCommentButton addTarget:self action:@selector(addComment) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = [TTCensorshipControl withDelegate:self];
    
    // Dismiss in viewDidAppear
    if (self.view.tag == 2) {
        return;
    }
    
    // So we know if we need to load the comments or not after loading the yak
    // if (self.view.tag) load comments, else they will be loaded here
    self.view.tag = 1;
    
    [self.refreshControl addTarget:self action:@selector(reloadComments) forControlEvents:UIControlEventValueChanged];
    
    if (self.yak) {
        [self reloadCommentSectionData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.view.tag == 2) {
        [self dismissAndNotifyYakRemoved];
    }
}

- (void)reloadComments {
    if (self.loadingData) return;
    
    self.loadingData = YES;
    [[YYClient sharedClient] getCommentsForYak:self.yak completion:^(NSArray *collection, NSError *error) {
        self.loadingData = NO;
        
        [self displayOptionalError:error message:@"Failed to load comments"];
        if (!error) {
            [self.dataSource setArray:collection];
            [self.tableView reloadSection:0];
            [self.refreshControl endRefreshing];
        }
    }];
}

- (void)reloadCommentSectionData {
    // Delete button
    if ([self.yak.authorIdentifier isEqualToString:[YYClient sharedClient].currentUser.identifier]) {
        id delete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deletePost)];
        self.navigationItem.rightBarButtonItem = delete;
    }
    
    // Load comments
    [self reloadComments];
}

- (void)deletePost {
    [self.navigationController popViewControllerAnimated:YES];
    
    [TBNetworkActivity push];
    [[YYClient sharedClient] deleteYakOrComment:self.yak completion:^(NSError *error) {
        [TBNetworkActivity pop];
        [self displayOptionalError:error];
    }];
}

#pragma mark UITableViewDataSource

- (NSArray<YYComment*> *)arrayToUse {
    return self.showsAll ? self.dataSource.allObjects : self.dataSource;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TTCommentCell *cell = (id)[self.tableView dequeueReusableCellWithIdentifier:kCommentCellReuse];
    [self configureCell:cell forComment:self.arrayToUse[indexPath.row]];
    [cell layoutIfNeeded];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayToUse.count;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    YYComment *comment = self.arrayToUse[indexPath.row];
    
    if ([comment.authorIdentifier isEqualToString:[YYClient sharedClient].currentUser.identifier]) {
        [self showOptionsForComment:comment];
    }
}

- (void)showOptionsForComment:(YYComment *)comment {
    TBAlertController *delete = [TBAlertController alertViewWithTitle:@"More Options" message:nil];
    [delete setCancelButtonWithTitle:@"Cancel"];
    
    [delete addOtherButtonWithTitle:@"Delete" buttonAction:^(NSArray *textFieldStrings) {
        [TBNetworkActivity push];
        [[YYClient sharedClient] deleteYakOrComment:comment completion:^(NSError *error) {
            [TBNetworkActivity pop];
            [self displayOptionalError:error];
            if (!error) {
                [self reloadComments];
            }
        }];
    }];
    
    [delete show];
}

#pragma mark Cell configuration

- (void)configureCell:(TTCommentCell *)cell forComment:(YYComment *)comment {
    cell.titleLabel.text           = comment.body;
    cell.scoreLabel.attributedText = [@(comment.score) scoreStringForVote:comment.voteStatus];
    cell.ageLabel.text             = comment.created.relativeTimeString;
    cell.authorLabel.text          = comment.authorText;
    cell.votable                   = comment;
    cell.votingSwipesEnabled       = !self.yak.isReadOnly;
    cell.repliesEnabled            = !self.yak.isReadOnly;
    cell.replyAction               = ^{
        [self replyToUser:comment.username ?: comment.authorText];
    };
    
    [cell setIcon:comment.overlayIdentifier withColor:comment.backgroundIdentifier];
}

#pragma mark Replying

- (void)addComment {
    [self replyToUser:nil];
}

- (void)replyToUser:(NSString *)username {
    username = [username stringByAppendingString:@" "];
    [self.navigationController presentViewController:[TTReplyViewController initialText:username limit:-1 onSubmit:^(NSString *text, BOOL useHandle) {
        if (text.length > 200) {
            NSInteger i = 0;
            for (NSString *reply in [text brokenUpByCharacterLimit:200]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i++ * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self submitReplyToYak:reply useHandle:useHandle];
                });
            }
        } else {
            [self submitReplyToYak:text useHandle:useHandle];
        }
    }] animated:YES completion:nil];
}

- (void)submitReplyToYak:(NSString *)reply useHandle:(BOOL)useHandle {
    NSParameterAssert(reply.length < 200 && reply.length > 0);
    
    [[YYClient sharedClient] postComment:reply toYak:self.yak useHandle:useHandle completion:^(NSError *error) {
        [self displayOptionalError:error message:@"Failed to submit reply"];
        if (!error) {
            [self reloadComments];
        }
    }];
}

@end
