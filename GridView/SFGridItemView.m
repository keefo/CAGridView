//
//  SFGridItemView.m
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "SFGridItemView.h"

@interface SFGridItemView()
{
    CATextLayer *titleLayer;
}
@end

@implementation SFGridItemView

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [self init]) {
        self.reuseIdentifier = reuseIdentifier;
    }
    return self;
}

- (void)initProperties {
    [super initProperties];
    /// Item Default Content
    self.itemImage = nil;
    self.itemTitle = @"";
}

- (void)setItemTitle:(NSString *)itemTitle
{
    _itemTitle = itemTitle;
    if (titleLayer==nil) {
        titleLayer = [CATextLayer layer];
        [titleLayer setFont:@"Helvetica-Bold"];
        [titleLayer setFontSize:20];
        [titleLayer setAlignmentMode:kCAAlignmentCenter];
        [self addSublayer:titleLayer];
    }
    [titleLayer setFrame:NSMakeRect(0, 50, self.bounds.size.width, 40)];
    [titleLayer setString:itemTitle];
    NSLog(@"titleLayer=%@", titleLayer.string);
}

- (void)setNeedsDisplay{
    [super setNeedsDisplay];
    [titleLayer setNeedsDisplay];
}

#pragma mark - Reusing Grid View Items

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.itemImage = nil;
    self.itemTitle = @"";
}

#pragma mark - Notifications

- (void)clearHovering {
    [self setHovered:NO];
}

- (void)clearSelection {
    [self setSelected:NO];
}

#pragma mark - Accessors

- (void)setHovered:(BOOL)hovered {
    [super setHovered:hovered];
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self setNeedsDisplay];
}

@end
