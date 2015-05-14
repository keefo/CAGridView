//
//  AppDelegate.m
//  TestUIApp
//
//  Created by Xu Lian on 2015-05-13.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "AppDelegate.h"
#import "SFAppDelegate.h"

@interface AppDelegate ()
{
    UIKitView *chameleonNSView;
    SFAppDelegate *chameleonApp;
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    chameleonApp = [[SFAppDelegate alloc] init];
    [_chameleonNSView launchApplicationWithDelegate:chameleonApp afterDelay:0];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
