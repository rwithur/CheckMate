//
//  CMUserTrackingViewController.m
//  CheckMate
//
//  Created by Rwithu Menon on 03/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMUserTrackingViewController.h"

@interface CMUserTrackingViewController ()

@property (strong, nonatomic) NSArray *familyMembers;

@end

@implementation CMUserTrackingViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.navigationController.navigationBar setHidden: NO];
//    [self adjustNavBarOrigin];

}
- (void)viewDidLoad {
    [super viewDidLoad];

    self.currentUser = [PFUser currentUser];
    PFQuery *query = [PFUser query];
    [query whereKey:@"secret" equalTo:self.currentUser[@"secret"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        self.familyMembers = objects;
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)adjustNavBarOrigin
{
    CGRect r = self.navigationController.navigationBar.frame;
    r.origin = CGPointMake(0, 20);  // 20 is the height of the status bar
    self.navigationController.navigationBar.frame = r;
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
    cell.textLabel.text = user[@"name"];
    cell.detailTextLabel.text = user[@"address"];
    return cell;
}

 
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//#pragma mark - TRNQL Delegate
//- (void)smartAddressChange:(AddressEntry * __nullable)address error:(NSError * __nullable)error{
//    NSString *addressReceived = [address getAddress];
//    self.currentUser[@"address"] = addressReceived;
//    [self.tableView reloadData];
//}
//
//- (void)smartLocationChange:(LocationEntry * __nullable)location error:(NSError * __nullable)error {
//    NSLog(@"%@",error);
//    PFQuery *query = [PFUser query];
//    [query whereKey:@"username" equalTo:self.currentUser[@"username"]];
//    NSArray *array = [[NSArray alloc]init];
//    array = [query findObjects];
//    PFUser *user = [array firstObject];
//    CLLocation *locationReceived = [location getLocation];
//    CLLocationCoordinate2D coordinate = locationReceived.coordinate;
//    user[@"latitude"] = [NSString stringWithFormat:@"%f",coordinate.latitude];
//    user[@"longitude"] = [NSString stringWithFormat:@"%f",coordinate.longitude];
//    [user save];
//}

@end
