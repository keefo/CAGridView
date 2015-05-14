//
//  UIGridView.h
//  UIKit
//
//  Created by Xu Lian on 2015-05-13.
//
//

#import <UIKit/UIKit.h>
#import "UIGridViewCell.h"

extern NSString *const UIGridViewIndexSearch;

@class UIGridView;
@class UIGridViewCell;

@protocol UIGridViewDelegate <UIScrollViewDelegate>
@optional
- (NSIndexPath *)gridView:(UIGridView *)gridView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gridView:(UIGridView *)gridView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)gridView:(UIGridView *)gridView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gridView:(UIGridView *)gridView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)gridView:(UIGridView *)gridView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)gridView:(UIGridView *)gridView heightForFooterInSection:(NSInteger)section;
- (UIView *)gridView:(UIGridView *)gridView viewForHeaderInSection:(NSInteger)section;
- (UIView *)gridView:(UIGridView *)gridView viewForFooterInSection:(NSInteger)section;

- (void)gridView:(UIGridView *)gridView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gridView:(UIGridView *)gridView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)gridView:(UIGridView *)gridView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UIGridViewDataSource <NSObject>
@required
- (NSInteger)gridView:(UIGridView *)gridView numberOfItemsInSection:(NSInteger)section;
- (UIGridViewCell *)gridView:(UIGridView *)gridView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (NSInteger)numberOfSectionsInGridView:(UIGridView *)gridView;
- (NSString *)gridView:(UIGridView *)gridView titleForHeaderInSection:(NSInteger)section;
- (NSString *)gridView:(UIGridView *)gridView titleForFooterInSection:(NSInteger)section;

- (void)gridView:(UIGridView *)gridView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)gridView:(UIGridView *)gridView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
@end

typedef enum {
    UIGridViewStylePlain,
    UIGridViewStyleGrouped
} UIGridViewStyle;

typedef enum {
    UIGridViewScrollPositionNone,
    UIGridViewScrollPositionTop,
    UIGridViewScrollPositionMiddle,
    UIGridViewScrollPositionBottom
} UIGridViewScrollPosition;

typedef enum {
    UIGridViewRowAnimationFade,
    UIGridViewRowAnimationRight,
    UIGridViewRowAnimationLeft,
    UIGridViewRowAnimationTop,
    UIGridViewRowAnimationBottom,
    UIGridViewRowAnimationNone,
    UIGridViewRowAnimationMiddle
} UIGridViewRowAnimation;

@interface UIGridView : UIScrollView {
@private
    UIGridViewStyle _style;
    __unsafe_unretained id<UIGridViewDataSource> _dataSource;
    BOOL _needsReload;
    CGFloat _rowHeight;
    UIView *_tableHeaderView;
    UIView *_tableFooterView;
    UIView *_backgroundView;

    BOOL _allowsSelection;
    BOOL _allowsSelectionDuringEditing;
    BOOL _editing;
    NSIndexPath *_selectedRow;
    NSIndexPath *_highlightedRow;
    NSMutableDictionary *_cachedCells;
    NSMutableSet *_reusableCells;
    NSMutableArray *_sections;
    CGFloat _sectionHeaderHeight;
    CGFloat _sectionFooterHeight;
    
    struct {
        unsigned heightForHeaderInSection : 1;
        unsigned heightForFooterInSection : 1;
        unsigned viewForHeaderInSection : 1;
        unsigned viewForFooterInSection : 1;
        unsigned willSelectRowAtIndexPath : 1;
        unsigned didSelectRowAtIndexPath : 1;
        unsigned willDeselectRowAtIndexPath : 1;
        unsigned didDeselectRowAtIndexPath : 1;
        unsigned willBeginEditingRowAtIndexPath : 1;
        unsigned didEndEditingRowAtIndexPath : 1;
        unsigned titleForDeleteConfirmationButtonForRowAtIndexPath: 1;
    } _delegateHas;
    
    struct {
        unsigned numberOfSectionsInTableView : 1;
        unsigned titleForHeaderInSection : 1;
        unsigned titleForFooterInSection : 1;
        unsigned commitEditingStyle : 1;
        unsigned canEditRowAtIndexPath : 1;
    } _dataSourceHas;
}

- (id)initWithFrame:(CGRect)frame style:(UIGridViewStyle)style;
- (void)reloadData;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (NSArray *)indexPathsForRowsInRect:(CGRect)rect;
- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForCell:(UIGridViewCell *)cell;
- (NSArray *)indexPathsForVisibleRows;
- (NSArray *)visibleCells;
- (UIGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (UIGridViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (CGRect)rectForSection:(NSInteger)section;
- (CGRect)rectForHeaderInSection:(NSInteger)section;
- (CGRect)rectForFooterInSection:(NSInteger)section;
//- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath;
//- (CGRect)rectForIndexAtIndexPath:(NSIndexPath *)indexPath;
- (CGRect)rectForItemAtIndex:(NSInteger)index andSection:(NSInteger)section;

- (void)beginUpdates;
- (void)endUpdates;

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UIGridViewRowAnimation)animation;
- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UIGridViewRowAnimation)animation;

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UIGridViewRowAnimation)animation;	// not implemented
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UIGridViewRowAnimation)animation;	// not implemented

- (NSIndexPath *)indexPathForSelectedRow;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UIGridViewScrollPosition)scrollPosition;

- (void)scrollToNearestSelectedRowAtScrollPosition:(UIGridViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UIGridViewScrollPosition)scrollPosition animated:(BOOL)animated;

- (void)setEditing:(BOOL)editing animated:(BOOL)animate;

@property (nonatomic, assign) BOOL fixSectionHeader;
@property (nonatomic, readonly) UIGridViewStyle style;
@property (nonatomic, assign) id<UIGridViewDelegate> delegate;
@property (nonatomic, assign) id<UIGridViewDataSource> dataSource;
@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) UITableViewCellSeparatorStyle separatorStyle;
@property (nonatomic, retain) UIColor *separatorColor;
@property (nonatomic, retain) UIView *tableHeaderView;
@property (nonatomic, retain) UIView *tableFooterView;
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic) BOOL allowsSelection;
@property (nonatomic) BOOL allowsSelectionDuringEditing;	// not implemented
@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic) CGFloat sectionHeaderHeight;
@property (nonatomic) CGFloat sectionFooterHeight;

@end


