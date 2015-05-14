//
//  AppDelegate.h
//  TestUIApp
//
//  Created by Xu Lian on 2015-05-13.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <UIKit/UIKitView.h>

@class SFAppDelegate;

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet UIKitView *chameleonNSView;

@end

