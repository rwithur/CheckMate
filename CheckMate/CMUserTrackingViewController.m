//
//  CMUserTrackingViewController.m
//  CheckMate
//
//  Created by Rwithu Menon on 03/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMUserTrackingViewController.h"

#import <Parse/Parse.h>

#import "AppDelegate.h"
#import "Config.h"
#import "CMGroupChatView.h"
#import "CMLoginViewController.h"
#import "CMUserTrackingDetailsViewController.h"
#import "MBProgressHUD.h"

@interface CMUserTrackingViewController ()

@property (strong, nonatomic) PFUser *currentUser;
@property (strong, nonatomic) NSArray *familyMembers;
@property (strong, nonatomic) PFUser *selectedFamilyMember;

@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet UITableView *familyTableView;
@property (strong, nonatomic) UIView *noMembersView;

- (IBAction)inviteButtonTapped:(id)sender;
- (IBAction)chatPressed:(id)sender;

@end

@implementation CMUserTrackingViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setUpViews];
}

- (void)setUpViews {
    self.noMembersView = [[UIView alloc] initWithFrame:self.view.frame];
    self.noMembersView.backgroundColor = [UIColor clearColor];
    
    UILabel *matchesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
    matchesLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
    matchesLabel.numberOfLines = 2;
    matchesLabel.lineBreakMode = NSLineBreakByWordWrapping;
    matchesLabel.shadowColor = [UIColor lightTextColor];
    matchesLabel.textColor = CHECKMATE_DESCRIPTION_COLOUR;
    matchesLabel.shadowOffset = CGSizeMake(0, 1);
    matchesLabel.backgroundColor = [UIColor clearColor];
    matchesLabel.textAlignment =  NSTextAlignmentCenter;
    
    //Here is the text for when there are no results
    matchesLabel.text = @"No family members added. Please invite your family members to join.";
    
    
    self.noMembersView.hidden = YES;
    [self.noMembersView addSubview:matchesLabel];
    [self.familyTableView insertSubview:self.noMembersView belowSubview:self.familyTableView];
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"Family";
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:CHECKMATE_TITLE_COLOUR}];
    
    self.navigationController.navigationBar.tintColor = CHECKMATE_TITLE_COLOUR;
    self.navigationItem.rightBarButtonItem.tintColor = CHECKMATE_TITLE_COLOUR;
    
    [self.familyTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    self.inviteButton.backgroundColor = CHECKMATE_THEME_COLOUR;
    [self.inviteButton setTitleColor:CHECKMATE_TITLE_COLOUR forState:UIControlStateNormal];
    self.inviteButton.layer.cornerRadius = 15;
    self.inviteButton.clipsToBounds = YES;
    
    [NSTimer scheduledTimerWithTimeInterval:180.0 target:self selector:@selector(fetchObjects) userInfo:nil repeats:YES];
    [self populateDataSource];
}

- (void)fetchObjects {
    __block BOOL needsReload;
    for (PFUser *user in [self.familyMembers mutableCopy]) {
        [user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if([user updatedAt]!=[object updatedAt]) {
                needsReload = YES;
            }
        }];
        if (needsReload) {
            break;
        }
    }
}

- (void)populateDataSource {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.currentUser = appDelegate.currentUser;
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"secret" equalTo:self.currentUser[@"secret"]];
    [query whereKey:@"username" notEqualTo:self.currentUser[@"username"]];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            self.familyMembers = objects;
            [self.familyTableView reloadData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });

        }];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.familyMembers.count) {
        self.noMembersView.hidden = YES;
    } else {
        self.noMembersView.hidden = NO;
    }
    return self.familyMembers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                               reuseIdentifier:@"Cell"];
        
    PFUser *user = [self.familyMembers objectAtIndex:indexPath.row];
    cell.textLabel.text = [user[@"name"] capitalizedString];
    cell.detailTextLabel.text = user[@"address"]?user[@"address"]:@"";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedFamilyMember = [self.familyMembers objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"showTrackingDetailsSegue" sender:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    CMUserTrackingDetailsViewController *vc = [segue destinationViewController];
    vc.currentUser = self.selectedFamilyMember;
}


- (IBAction)inviteButtonTapped:(id)sender {
    [[CMLoginViewController new] familyLimitWithSecret:self.currentUser[@"secret"] ExceededWithCompletionBlock:^(BOOL success) {
        if (success) {
            UIAlertController * alert=   [UIAlertController
                                          alertControllerWithTitle:@"Error"
                                          message:@"Family already has 10 members"
                                          preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:
                                 ^(UIAlertAction * action) {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            NSURL *whatsappURL = [NSURL URLWithString:[self composeMessage]];
            if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
                [[UIApplication sharedApplication] openURL: whatsappURL];
            } else {
                UIAlertController *alert = [UIAlertController
                                            alertControllerWithTitle:@""
                                            message:@"WhatsApp is not installed.. Please install and try again.."
                                            preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
                
            }
        }
    }];
}

- (IBAction)chatPressed:(id)sender {
    CMGroupChatView *chatVC = [[CMGroupChatView alloc] init];
    chatVC.currentUser = self.currentUser;
        [self.navigationController pushViewController:chatVC animated:NO];
}

- (NSString *)composeMessage {
    NSString *message= [NSString stringWithFormat:@"whatsapp://send?text=Hey, I just started using the app CheckMate. Join the family that will help us stay in the loop 24/7. Use our secret code %@. Get the app and join me through....",self.currentUser[@"secret"]];
    message=[NSString stringWithFormat:@"%@",[message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return message;
}

@end
