//
//  ViewController.m
//  AccountsDemo
//
//  Created by David Sinclair on 2016-02-04.
//  Copyright © 2016 Dejal Systems, LLC. All rights reserved.
//

#import "ViewController.h"
@import Accounts;
@import Social;

@interface ViewController ()

@property (nonatomic, strong) ACAccountStore *accountStore;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)loadAccounts:(id)sender {
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    // Request access from the user to use their Twitter accounts:
    [self.accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error)
     {
         if (error)
         {
             NSLog(@"Twitter accounts error: %@", error);  // log
             
             self.textView.string = error.localizedDescription;
         }
         
         if (granted)
         {
             // Get the list of Twitter accounts:
             NSArray *accounts = [self.accountStore accountsWithAccountType:accountType];
             
             NSLog(@"Twitter accounts: %@", accounts);  // log
             
             self.textView.string = accounts.description;
         }
     }];
}

- (ACAccountStore *)accountStore {
    if (!_accountStore)
    {
        self.accountStore = [ACAccountStore new];
    }
    
    return _accountStore;
}

@end
