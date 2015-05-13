//
//  SFGridItemBaseView.h
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#define SFItemIndexUndefined NSNotFound

@interface SFGridItemBase : CALayer
@property (strong) NSString *reuseIdentifier;
@property (readonly, nonatomic) BOOL isReuseable;
@property (assign) NSInteger index;

/**
 The object that the receiving item view represents
 */
@property (assign) id representedObject;

#pragma mark - Selection and Hovering
/** @name Selection and Hovering */
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL selectable;
@property (nonatomic, assign) BOOL hovered;

+ (CGSize)defaultItemSize;
- (void)prepareForReuse;
- (void)initProperties;

@end
