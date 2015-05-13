//
//  TestView.m
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "TestView.h"

@implementation TestView

- (void)awakeFromNib
{
    [self setWantsLayer:YES];
    CALayer *hostedLayer = [CALayer layer];
    hostedLayer.backgroundColor = [[NSColor redColor] CGColor];
    [self setLayer:hostedLayer];
    
    CALayer *item = [CALayer layer];
    item.frame = NSMakeRect(100, 100, 90, 90);
    item.backgroundColor = [[NSColor blueColor] CGColor];
    [self.layer addSublayer:item];
}

@end
