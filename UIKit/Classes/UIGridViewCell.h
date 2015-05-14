//
//  UIGridViewCell.h
//  UIKit
//
//  Created by Xu Lian on 2015-05-13.
//
//

#import <UIKit/UIKit.h>

typedef enum {
    UIGridViewCellAccessoryNone,
    UIGridViewCellAccessoryDisclosureIndicator,
    UIGridViewCellAccessoryDetailDisclosureButton,
    UIGridViewCellAccessoryCheckmark
} UIGridViewCellAccessoryType;

typedef enum {
    UIGridViewCellSeparatorStyleNone,
    UIGridViewCellSeparatorStyleSingleLine,
    UIGridViewCellSeparatorStyleSingleLineEtched
} UIGridViewCellSeparatorStyle;

typedef enum {
    UIGridViewCellStyleDefault,
    UIGridViewCellStyleValue1,
    UIGridViewCellStyleValue2,
    UIGridViewCellStyleSubtitle
} UIGridViewCellStyle;

typedef enum {
    UIGridViewCellSelectionStyleNone,
    UIGridViewCellSelectionStyleBlue,
    UIGridViewCellSelectionStyleGray
} UIGridViewCellSelectionStyle;

typedef enum {
    UIGridViewCellEditingStyleNone,
    UIGridViewCellEditingStyleDelete,
    UIGridViewCellEditingStyleInsert
} UIGridViewCellEditingStyle;

@class UIGridViewCellSeparator, UILabel, UIImageView;



@interface UIGridViewCell : UIView {
@private
    UIGridViewCellStyle _style;
    UIGridViewCellSeparator *_seperatorView;
    UIView *_contentView;
    UILabel *_textLabel;
    UILabel *_detailTextLabel; // not yet displayed!
    UIImageView *_imageView;
    UIView *_backgroundView;
    UIView *_selectedBackgroundView;
    UIGridViewCellAccessoryType _accessoryType;
    UIView *_accessoryView;
    UIGridViewCellAccessoryType _editingAccessoryType;
    UIGridViewCellSelectionStyle _selectionStyle;
    NSInteger _indentationLevel;
    BOOL _editing;
    BOOL _selected;
    BOOL _highlighted;
    BOOL _showingDeleteConfirmation;
    NSString *_reuseIdentifier;
    CGFloat _indentationWidth;
}

- (id)initWithStyle:(UIGridViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;
- (void)prepareForReuse;

@property (nonatomic, readonly, retain) UIView *contentView;
@property (nonatomic, readonly, retain) UILabel *textLabel;
@property (nonatomic, readonly, retain) UILabel *detailTextLabel;
@property (nonatomic, readonly, retain) UIImageView *imageView;
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UIView *selectedBackgroundView;
@property (nonatomic) UIGridViewCellSelectionStyle selectionStyle;
@property (nonatomic) NSInteger indentationLevel;
@property (nonatomic) UIGridViewCellAccessoryType accessoryType;
@property (nonatomic, retain) UIView *accessoryView;
@property (nonatomic) UIGridViewCellAccessoryType editingAccessoryType;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isEditing) BOOL editing; // not yet implemented
@property (nonatomic, readonly) BOOL showingDeleteConfirmation;  // not yet implemented
@property (nonatomic, readonly, copy) NSString *reuseIdentifier;
@property (nonatomic, assign) CGFloat indentationWidth; // 10 per default

@end


