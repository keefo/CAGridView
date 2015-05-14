//
//  SFGridItemBaseView.m
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "SFGridItemBase.h"

NSString *const kSFGridViewDefaultItemIdentifier = @"SFGridViewItem";

@implementation SFGridItemBase


+ (CGSize)defaultItemSize {
    return NSMakeSize(310, 225);
}

- (void)dealloc {
}

- (id)init {
    if (self = [super init]) {
        [self initProperties];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect {
    ;
    if (self = [super init]) {
        [self initProperties];
        self.frame = frameRect;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initProperties];
    }
    return self;
}

- (void)initProperties {
    /// Reusing Grid View Items
    self.reuseIdentifier = kSFGridViewDefaultItemIdentifier;
    self.index = SFItemIndexUndefined;
}

- (void)prepareForReuse {
    self.index = SFItemIndexUndefined;
    self.selected = NO;
    self.selectable = YES;
    self.hovered = NO;
}

- (BOOL)isReuseable {
    return (self.selected ? NO : YES);
}

- (void)selectAll:(NSNotification *)notification {
    [self setSelected:YES];
}

- (void)deSelectAll:(NSNotification *)notification {
    [self setSelected:NO];
}

- (void)setOpaque:(BOOL)opaque
{
    [super setOpaque:1];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    NSLog(@"setFrame=%@", NSStringFromRect(frame));
}

@end
