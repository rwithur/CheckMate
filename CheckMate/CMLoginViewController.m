//
//  CMLoginViewController.m
//  CheckMate
//
//  Created by Rwithu Menon on 02/11/15.
//  Copyright © 2015 Rwithu Menon. All rights reserved.
//

#import "CMLoginViewController.h"

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

#import "AppDelegate.h"
#import "Config.h"
#import "CMUserTrackingViewController.h"

@interface CMLoginViewController ()

@property (strong, nonatomic) NSString *familyName;
@property (strong, nonatomic) NSString *adminName;
@property (strong, nonatomic) NSString *secret;

@property (strong, nonatomic) UIAlertController *familyNameAlert;
@property (strong, nonatomic) UIAlertController *userNameAlert;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLAbel;
@property (weak, nonatomic) IBOutlet UILabel *orLabel;

@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;

- (IBAction)createTapped:(id)sender;
- (IBAction)joinTapped:(id)sender;

@end

@implementation CMLoginViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    [self setUpViews];
}

- (void)setUpViews {
    [self.navigationController.navigationBar setBarTintColor:CHECKMATE_THEME_COLOUR];
    self.navigationController.navigationBar.translucent = NO;
    
    self.descriptionLAbel.textColor = CHECKMATE_DESCRIPTION_COLOUR;
    self.orLabel.textColor = CHECKMATE_DESCRIPTION_COLOUR;
    
    self.createButton.backgroundColor = CHECKMATE_THEME_COLOUR;
    [self.createButton setTitleColor:CHECKMATE_TITLE_COLOUR forState:UIControlStateNormal];
    self.createButton.layer.cornerRadius = 15;
    self.createButton.clipsToBounds = YES;
    
    self.joinButton.backgroundColor = CHECKMATE_THEME_COLOUR;
    [self.joinButton setTitleColor:CHECKMATE_TITLE_COLOUR forState:UIControlStateNormal];
    self.joinButton.layer.cornerRadius = 15;
    self.joinButton.clipsToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)generateSecretKeyWithCompletionBlock:(compBlock)block {
    self.secret = [NSString stringWithFormat:@"%u", arc4random_uniform(8999) + 1000];
    PFQuery *query = [PFQuery queryWithClassName:@"Family"];
    [query whereKey:@"secret" equalTo:[NSString stringWithFormat:@"%@",self.secret]];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if ([objects count]>0) {
                [self generateSecretKeyWithCompletionBlock:block];
            } else {
                block(YES);
            }
        } else {
            NSString *errorString = [[error userInfo] objectForKey:@"error"];
            NSLog(@"Error: %@", errorString);
            block(NO);
        }
    }];
}

- (void)searchForFamilyWithSecretKey:(NSString *)secret {
    PFQuery *query = [PFQuery queryWithClassName:@"Family"];
    [query whereKey:@"secret" equalTo:[NSString stringWithFormat:@"%@",secret]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (!objects.count) {
                UIAlertController * alert=   [UIAlertController
                                              alertControllerWithTitle:@"Result not found"
                                              message:@"Oops..No family found with this secret code.."
                                              preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:
                                     ^(UIAlertAction * action) {
                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                     }];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                self.familyName = objects.firstObject[@"name"];
                self.secret = objects.firstObject[@"secret"];
                
                [self familyLimitWithSecret:self.secret ExceededWithCompletionBlock:^(BOOL success) {
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
                        UIAlertController * alert=   [UIAlertController
                                                      alertControllerWithTitle:@""
                                                      message:@"Enter your name"
                                                      preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       self.adminName = ((UITextField *)[alert.textFields objectAtIndex:0]).text;
                                                                       [self signUpUserWithCompletionBlock:nil];
                                                                   }];
                        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                                       }];
                        [alert addAction:ok];
                        [alert addAction:cancel];
                        
                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                            textField.placeholder = @"Your name";
                        }];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }
        }
    }];
    
}

- (void)signUpUserWithCompletionBlock:(compBlock)compBlock {
    
    PFUser *user = [PFUser user];
    user.username = [NSString stringWithFormat:@"%@%@%@",self.adminName,self.familyName,self.secret];
    user.password = @"my pass";
    
    user[@"name"] = self.adminName;
    user[@"secret"] = self.secret;
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [self navigateToHomePageForUser: user];
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:@"YES" forKey:@"loggedIn"];
            [userDefaults setObject:self.adminName forKey:@"username"];
            [userDefaults setObject:user[@"secret"] forKey:@"password"];
            [userDefaults synchronize];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate initSinchClient:user[@"username"]];
            if (compBlock) {
                compBlock(YES);
            }
            
        } else {
            NSString *errorString = [error userInfo][@"error"];   // Show the errorString somewhere and let the user try again.
            NSLog(@"Error: %@", errorString);
            UIAlertController * alert=   [UIAlertController
                                          alertControllerWithTitle:@"Error"
                                          message:@"An error occured.. Please try again"
                                          preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:
                                 ^(UIAlertAction * action) {
                                     [alert dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
            compBlock(NO);
        }
    }];
}

- (void)familyLimitWithSecret:(NSString *)secret ExceededWithCompletionBlock:(compBlock)block {
    PFQuery *query = [PFUser query];
    [query whereKey:@"secret" equalTo:secret];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects.count >= 10) {
            block(YES);
        } else {
            block(NO);
        }
    }];
}

- (void)navigateToHomePageForUser:(PFUser*)user {
    
    UIStoryboard *storyBoard = [self storyboard];
    CMUserTrackingViewController *userTrackingView  = [storyBoard instantiateViewControllerWithIdentifier:@"CMUserTrackingViewController"];
    [self.navigationController pushViewController: userTrackingView animated:YES];
}

- (IBAction)createTapped:(id)sender {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@""
                                  message:@"Enter the details"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   
                                                   self.familyName = ((UITextField *)[alert.textFields objectAtIndex:0]).text;
                                                   self.adminName = ((UITextField *)[alert.textFields objectAtIndex:1]).text;
                                                   [self generateSecretKeyWithCompletionBlock:^(BOOL success) {
                                                       if (success) {
                                                           [self signUpUserWithCompletionBlock:^(BOOL success) {
                                                               if (success) {
                                                                   PFObject *familyObject = [PFObject objectWithClassName:@"Family"];
                                                                   familyObject[@"name"] = self.familyName;
                                                                   familyObject[@"adminName"] = self.adminName;
                                                                   familyObject[@"secret"] = self.secret;
                                                                   [familyObject saveInBackground];
                                                               }
                                                           }];
                                                       } else {
                                                           UIAlertController * alert=   [UIAlertController
                                                                                         alertControllerWithTitle:@"Error"
                                                                                         message:@"An error occured.. Please try again"
                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                                                           UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:
                                                                                ^(UIAlertAction * action) {
                                                                                    [alert dismissViewControllerAnimated:YES completion:nil];
                                                                                }];
                                                           [alert addAction:ok];
                                                           [self presentViewController:alert animated:YES completion:nil];
                                                       }
                                                   }];
                                                   
                                               }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Family name";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Your name";
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)joinTapped:(id)sender {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Login"
                                  message:@"Enter the family secret"
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   [self searchForFamilyWithSecretKey:((UITextField *)[alert.textFields objectAtIndex:0]).text];
                                               }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Secret";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
