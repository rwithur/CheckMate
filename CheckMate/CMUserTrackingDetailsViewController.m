//
//  CMUserTrackingDetailsViewController.m
//  CheckMate
//
//  Created by Rwithu Menon on 09/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMUserTrackingDetailsViewController.h"

#import <MapKit/MapKit.h> 

#import "Config.h"
#import "CMAddressPin.h"

@interface CMUserTrackingDetailsViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackingDetailsLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (weak, nonatomic) IBOutlet UIButton *openInMapsButton;

- (IBAction)openInMapsPressed:(id)sender;
@end

@implementation CMUserTrackingDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) configureView {
    self.nameLabel.textColor = CHECKMATE_TITLE_COLOUR;
    self.trackingDetailsLabel.textColor = CHECKMATE_TITLE_COLOUR;
    self.lastUpdatedLabel.textColor = CHECKMATE_TITLE_COLOUR;

    self.nameLabel.text = [self.currentUser[@"name"] capitalizedString];
    self.trackingDetailsLabel.text = [[NSString stringWithFormat:@"%@\nActivity: %@",self.currentUser[@"address"]?self.currentUser[@"address"]:@" ",self.currentUser[@"activity"]?self.currentUser[@"activity"]:@"Not updated"] capitalizedString];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss z"];
    NSDate *date = [self.currentUser updatedAt];
    NSString *dateString = [dateFormatter stringFromDate:date];
    self.lastUpdatedLabel.text = [NSString stringWithFormat:@"Last updated at: %@", dateString];
    
    CLLocation *locationReceived = [[CLLocation alloc] initWithLatitude:[self.currentUser[@"latitude"] doubleValue] longitude:[self.currentUser[@"longitude"] doubleValue]];
    CLLocationCoordinate2D coordinate = locationReceived.coordinate;
    MKCoordinateRegion region;
    region.center.latitude = locationReceived.coordinate.latitude;
    region.center.longitude = locationReceived.coordinate.longitude;
    region.span.latitudeDelta = 0.01;
    region.span.longitudeDelta = 0.01;
    
    [self.mapView setRegion:region animated:YES];
    CMAddressPin *addAnnotation = [[CMAddressPin alloc] initWithCoordinate:coordinate];
    [self.mapView addAnnotation:addAnnotation];
}

- (IBAction)openInMapsPressed:(id)sender {
    if (!(self.currentUser[@"latitude"] || self.currentUser[@"longitude"])) {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@""
                                    message:@"Location is not updated"
                                    preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Open in Maps" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Apple Maps",@"Google Maps", nil];
        [sheet showInView:self.view];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    CLLocation *locationReceived = [[CLLocation alloc] initWithLatitude:[self.currentUser[@"latitude"] doubleValue] longitude:[self.currentUser[@"longitude"] doubleValue]];
    CLLocationCoordinate2D coordinate = locationReceived.coordinate;
    if (buttonIndex==0) {
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:placemark];
        item.name = self.currentUser[@"name"];
        MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
        [item openInMapsWithLaunchOptions:@{ MKLaunchOptionsMapSpanKey : [NSValue valueWithMKCoordinateSpan:span] }];
    } else if (buttonIndex==1) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?q=%f,%f&zoom=15",coordinate.latitude,coordinate.longitude]];
        if (![[UIApplication sharedApplication] canOpenURL:url]) {
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@""
                                        message:@"Google Maps is not installed"
                                        preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
            
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}
@end
