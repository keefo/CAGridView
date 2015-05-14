//
//  ChameleonAppDelegate.h
//  TestUIApp
//
//  Created by Xu Lian on 2015-05-13.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SFAppDelegate : NSObject <UIApplicationDelegate, UIGridViewDataSource>
{
    UIWindow *window;
    UIView *sidebarView;
    UIGridView *gridView;
    
    UIImageView *appleView;
    UIButton *sillyButton;
    UISplitViewController *splitViewController;
}

@end
