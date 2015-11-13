//
//  CMUserTrackingViewController.m
//  CheckMate
//
//  Created by Rwithu Menon on 03/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMUserTrackingViewController.h"
#import "MBProgressHUD.h"
#import "CMUserTrackingDetailsViewController.h"
#import "AppDelegate.h"
#import "CMGroupChatView.h"
#import "CMLoginViewController.h"

@interface CMUserTrackingViewController ()

@property (strong, nonatomic) PFUser *currentUser;
@property (strong, nonatomic) NSArray *familyMembers;
@property (strong, nonatomic) PFUser *selectedFamilyMember;

@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet UITableView *familyTableView;

- (IBAction)inviteButtonTapped:(id)sender;
- (IBAction)chatPressed:(id)sender;

@end

@implementation CMUserTrackingViewController

- (void) viewWillAppear:(BOOL)animated {
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"Family";
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor colorWithRed:0.125f green:0.373f blue:0.353f alpha:1.00f]}];

    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.125f green:0.373f blue:0.353f alpha:1.00f];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.125f green:0.373f blue:0.353f alpha:1.00f];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.familyTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];

    self.inviteButton.backgroundColor = [UIColor colorWithRed:0.416f green:0.800f blue:0.796f alpha:1.00f];
    [self.inviteButton setTitleColor:[UIColor colorWithRed:0.125f green:0.373f blue:0.353f alpha:1.00f] forState:UIControlStateNormal];
    self.inviteButton.layer.cornerRadius = 15;
    self.inviteButton.clipsToBounds = YES;
    [NSTimer scheduledTimerWithTimeInterval:180.0 target:self selector:@selector(fetchObjects) userInfo:nil repeats:YES];
    [self populateDataSource];
}

- (void) fetchObjects {
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

- (void) populateDataSource {
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
    return self.familyMembers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                               reuseIdentifier:@"Cell"];
        
    PFUser *user = [self.familyMembers objectAtIndex:indexPath.row];
    cell.textLabel.text = [user[@"name"] capitalizedString];
    cell.detailTextLabel.text = user[@"address"]?user[@"address"]:@"Not updated";
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
