# AccountsDemo

I [blogged about some critical bugs in OS X](http://www.dejal.com/blog/2016/04/apples-neglected-os) that Apple hasn't fixed, including getting a "Setting TCC failed" error when trying to access Twitter accounts (and other kinds of accounts).

The problem is that calling `-[ACAccountStore requestAccessToAccountsWithType:options:completion:]` on OS X 10.11 for a new app will ask the user for permission then always give the error "Setting TCC failed."  (Reported as Radar #23114308 for any Apple people reading this.)

While this bug remains, I came across a solution in [Apple's developer forums](https://forums.developer.apple.com/message/69921).  It's a hack, and probably won't work in sandboxed apps, but does work for non-sandboxed apps.

Basically, if that error is received, we can edit the "~/Library/Accounts/Accounts3.sqlite" database directly via the `sqlite3` command line tool.

I've put together this open-source demo app to show this technique.

When the error is detected, it calls a method to send the SQL:


            [self sendSQL:[NSString stringWithFormat:@"insert into ZAUTHORIZATION (Z_ENT, Z_OPT, ZACCOUNTTYPE, ZBUNDLEID, ZGRANTEDPERMISSIONS) values (5, 1, (select Z_PK from ZACCOUNTTYPE where ZIDENTIFIER = 'com.apple.twitter'), '%@', '')", [NSBundle mainBundle].bundleIdentifier] completionHandler:^{
                NSLog(@"Workaround completed");  // log
                
                [self loadAccounts:sender];
            }];

*(Sorry Swifties; I wrote the demo project a while ago for my original Radar bug report, so it's in Objective-C.)*

The `-sendSQL:` method simply uses `NSTask` to execute the `sqlite3` command on the database:

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

The AccountsDemo sample project includes a button to load the Twitter accounts, a checkbox to use the above hack, and a button to remove the app from the accounts database (so you can re-try it).  Try clicking the load button with the checkbox unchecked, to confirm that you get the error, then check the box and try loading again, and it should work.

![Screenshot](http://www.dejal.com/developer/demos/accountsdemo.png)

This is available without a license; you're welcome to use it if useful.

