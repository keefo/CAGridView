//
//  AppDelegate.m
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self.gridView reloadData];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSUInteger)gridView:(SFGridView *)gridView numberOfItemsInSection:(NSInteger)section;
{
    return 10;
}

- (SFGridItemView *)gridView:(SFGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section;
{
    static NSString *reuseIdentifier = @"SFGridViewItem";
    
    SFGridItemView *item = [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (item == nil) {
        item = [[SFGridItemView alloc] initWithReuseIdentifier:reuseIdentifier];
    }

    item.itemTitle = [NSString stringWithFormat:@"%lu", index+1];
    item.itemImage = [NSImage imageNamed:NSImageNameFolder];
    item.masksToBounds = YES;
    item.cornerRadius = 10;
    item.backgroundColor = [[[NSColor blueColor] colorWithAlphaComponent:0.6] CGColor];

    return item;
}

@end
