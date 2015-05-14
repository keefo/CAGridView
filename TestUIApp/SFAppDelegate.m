//
//  ChameleonAppDelegate.m
//  TestUIApp
//
//  Created by Xu Lian on 2015-05-13.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "SFAppDelegate.h"

@implementation SFAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    window.backgroundColor = [UIColor whiteColor];
    window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
 
    sidebarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, window.frame.size.height)];
    sidebarView.backgroundColor = [UIColor darkGrayColor];
    sidebarView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
    [window addSubview:sidebarView];

    gridView = [[UIGridView alloc] initWithFrame:CGRectMake(120, 0, NSWidth(window.frame)-120, window.frame.size.height) style:UIGridViewStyleGrouped];
    gridView.backgroundColor = [UIColor lightGrayColor];
    gridView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [window addSubview:gridView];
    gridView.allowsSelectionDuringEditing = YES;
    gridView.allowsSelection = YES;
    gridView.sectionHeaderHeight = 40;
    gridView.fixSectionHeader= YES;
    
//    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, gridView.bounds.size.width, 50)];
//    v.backgroundColor = [UIColor blueColor];
//    [gridView setTableHeaderView:v];
    
    [gridView setDataSource:self];

    /*
    splitViewController = [[UISplitViewController alloc] init];
    [splitViewController.view setFrame:window.bounds];
    [window addSubview:splitViewController.view];
    
    appleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"apple.png"]];
    sillyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sillyButton setTitle:@"Click Me!" forState:UIControlStateNormal];
    [sillyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sillyButton addTarget:self action:@selector(moveTheApple:) forControlEvents:UIControlEventTouchUpInside];
    sillyButton.frame = CGRectMake(0,300,200,50);

     [window addSubview:appleView];
     [window addSubview:sillyButton];
    */
    
    [window makeKeyAndVisible];
    
    [gridView reloadData];
}


- (void)moveTheApple:(id)sender
{
    [UIView beginAnimations:@"moveTheApple" context:nil];
    [UIView setAnimationDuration:3];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    if (CGAffineTransformIsIdentity(appleView.transform)) {
        appleView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        appleView.center = [window convertPoint:window.center toView:appleView.superview];
    } else {
        appleView.transform = CGAffineTransformIdentity;
        appleView.frame = CGRectMake(0,0,256,256);
    }
    
    [UIView commitAnimations];
}

#pragma mark - GridView Datasource

- (NSInteger)numberOfSectionsInGridView:(UITableView *)thegridView;
{
    return 10;
}

- (NSString *)gridView:(UIGridView *)thegridView titleForHeaderInSection:(NSInteger)section;
{
    return [NSString stringWithFormat:@"Section %lu", section];
}

- (NSInteger)gridView:(UIGridView *)thegridView numberOfItemsInSection:(NSInteger)section;
{
    return 30;
}

- (UIGridViewCell *)gridView:(UIGridView *)thegridView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    UIGridViewCell *cell = [thegridView dequeueReusableCellWithIdentifier:@"test"];
    if (cell==nil) {
        cell = [[UIGridViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"test"];
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    }
    UIImage *img = [UIImage imageNamed:NSImageNameFolderBurnable];
    cell.imageView.image = img;
    //cell.textLabel.text = @"xxx";
    return cell;
}

@end
