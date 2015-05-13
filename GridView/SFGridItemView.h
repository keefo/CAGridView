//
//  SFGridItemView.h
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "SFGridItemBase.h"

@interface SFGridItemView : SFGridItemBase

#pragma mark - Item Default Content
@property (strong, nonatomic) IBOutlet NSImage *itemImage;
@property (strong, nonatomic) IBOutlet NSString *itemTitle;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
