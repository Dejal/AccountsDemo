//
//  ViewController.h
//  AccountsDemo
//
//  Created by David Sinclair on 2016-02-04.
//  Copyright © 2016 Dejal Systems, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSButton *loadButton;
@property (strong) IBOutlet NSTextView *textView;

- (IBAction)loadAccounts:(id)sender;

@end

