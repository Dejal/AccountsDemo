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
@property (nonatomic) BOOL triedHack;

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
    [self.accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (error) {
            NSLog(@"Twitter accounts error: %@", error);  // log
            
            [self updateTextWithString:error.localizedDescription];
        }
        
        // A hack to work around an OS X 10.11 bug:
        if (self.useHackCheck.state && !self.triedHack && [error.domain isEqualToString:@"com.apple.accounts"] && error.code == 1) {
            NSLog(@"Trying to work around OS X bug: %@", error);  // log
            
            self.triedHack = YES;
            
            [self sendSQL:[NSString stringWithFormat:@"insert into ZAUTHORIZATION (Z_ENT, Z_OPT, ZACCOUNTTYPE, ZBUNDLEID, ZGRANTEDPERMISSIONS) values (5, 1, (select Z_PK from ZACCOUNTTYPE where ZIDENTIFIER = 'com.apple.twitter'), '%@', '')", [NSBundle mainBundle].bundleIdentifier] completionHandler:^{
                NSLog(@"Workaround completed");  // log
                
                [self loadAccounts:sender];
            }];
        } else {
            [self finishLoadAccountsForAccountType:accountType granted:granted];
        }
    }];
}

- (IBAction)removeFromAccounts:(id)sender {
    [self sendSQL:[NSString stringWithFormat:@"delete from ZAUTHORIZATION where ZBUNDLEID = '%@';", [NSBundle mainBundle].bundleIdentifier] completionHandler:^{
        [self updateTextWithString:@"Removed"];
    }];
}

- (void)updateTextWithString:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.string = string;
    });
}

- (void)sendSQL:(NSString *)sql completionHandler:(void (^)(void))handler {
    // Based on code from https://forums.developer.apple.com/message/69921
    NSURL *libraryURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *databaseURL = [libraryURL URLByAppendingPathComponent:@"Accounts/Accounts3.sqlite"];
    NSString *command = [NSString stringWithFormat:@"sqlite3 %@ \"%@\"", databaseURL.path, sql];
    
    NSTask *task = [NSTask new];
    
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", command];
    
    if (handler) {
        task.terminationHandler = ^(NSTask *localTask) {
            handler();
        };
    };
    
    [task launch];
}

- (void)finishLoadAccountsForAccountType:(ACAccountType *)accountType granted:(BOOL)granted {
    self.triedHack = NO;
    
    if (granted) {
        // Get the list of Twitter accounts:
        NSArray *accounts = [self.accountStore accountsWithAccountType:accountType];
        
        NSLog(@"Twitter accounts: %@", accounts);  // log
        
        [self updateTextWithString:accounts.description];
    }
}

- (ACAccountStore *)accountStore {
    if (!_accountStore) {
        self.accountStore = [ACAccountStore new];
    }
    
    return _accountStore;
}

@end
