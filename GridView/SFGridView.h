//
//  SFGridView.h
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SFGridItemView.h"

/// Notifications
/// All notifications have the sender `SFGridView` as object parameter
FOUNDATION_EXPORT NSString *const SFGridViewSelectAllItemsNotification;
FOUNDATION_EXPORT NSString *const SFGridViewDeSelectAllItemsNotification;


/// the userInfo dictionary of these notifications contains the item index
/// wrapped in a NSNumber object with the key `SFGridViewItemIndexKey`
FOUNDATION_EXPORT NSString *const SFGridViewWillHoverItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewWillUnhoverItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewWillSelectItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewDidSelectItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewWillDeselectItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewDidDeselectItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewDidClickItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewDidDoubleClickItemNotification;
FOUNDATION_EXPORT NSString *const SFGridViewRightMouseButtonClickedOnItemNotification;


/// these keys are use for the notification userInfo dictionary (see above)
FOUNDATION_EXPORT NSString *const SFGridViewItemKey;
FOUNDATION_EXPORT NSString *const SFGridViewItemIndexKey;
FOUNDATION_EXPORT NSString *const SFGridViewItemsIndexSetKey;



@class SFGridView;

@protocol SFGridViewDelegate <NSObject>

@optional
- (void)gridView:(SFGridView *)gridView willHoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView willUnhoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView willSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView willDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView willDeselectAllItems:(NSArray *)theSelectedItems;
- (void)gridViewDidDeselectAllItems:(SFGridView *)gridView;
- (void)gridView:(SFGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section;
- (void)gridView:(SFGridView *)gridView didActivateContextMenuWithIndexes:(NSIndexSet *)indexSet inSection:(NSUInteger)section;

@end

#pragma mark - SFGridViewDataSource

@protocol SFGridViewDataSource <NSObject>

- (NSUInteger)gridView:(SFGridView *)gridView numberOfItemsInSection:(NSInteger)section;
- (SFGridItemView *)gridView:(SFGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section;


@optional
- (NSUInteger)numberOfSectionsInGridView:(SFGridView *)gridView;
- (NSString *)gridView:(SFGridView *)gridView titleForHeaderInSection:(NSInteger)section;
- (NSArray *)sectionIndexTitlesForGridView:(SFGridView *)gridView;

@end




@interface SFGridView : NSView

#pragma mark - Managing the Delegate and the Data Source
/** @name Managing the Delegate and the Data Source */
@property (nonatomic, assign) IBOutlet id<SFGridViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<SFGridViewDataSource> dataSource;

/**
 Property for the background color of the grid view.
 
 This color (or pattern image) will be assigned to the enclosing scroll view. In the phase of initializing `SFGridView` will
 send the enclosing scroll view a `setDrawsBackground` message with `YES` as parameter value. So it's guaranteed the background
 will be drawn even if you forgot to set this flag in interface builder.
 
 If you don't use this property, the default value is `[NSColor controlColor]`.
 */
@property (nonatomic, strong) NSColor *backgroundColor;

/**
 Property for setting the grid view item size.
 
 You can set this property programmatically to any value you want. On each change of this value `SFGridView` will automatically
 refresh the entire visible grid view with an animation effect.
 */
@property (nonatomic, assign) NSSize itemSize;


#pragma mark - Creating GridView Items
/** @name Creating GridView Items */

/**
 Returns a reusable grid view item object located by its identifier.
 
 @param identifier  A string identifying the grid view item object to be reused. This parameter must not be nil.
 @return A SFGridViewItem object with the associated identifier or nil if no such object exists in the reusable queue.
 */
- (id)dequeueReusableItemWithIdentifier:(NSString *)identifier;


#pragma mark - Managing Selections and Hovering
/** @name Managing Selections */

/**
 Property for setting whether the grid view allows item selection or not.
 
 The default value is `YES`.
 */
@property (nonatomic, assign) BOOL allowsSelection;

/**
 Property that indicates whether the grid view should allow multiple item selection or not.
 
 If you have this property set to `YES` with actually many selected items, all these items will be unselect on setting `allowsMultipleSelection` to `NO`.
 
 @param YES The grid view allows multiple item selection.
 @param NO  The grid view don't allow multiple item selection.
 */
@property (nonatomic, assign) BOOL allowsMultipleSelection;

/**
 Property indicates if the mouse drag operation can be used to select multiple items.
 
 If you have this property set to `YES` you must also set `allowsMultipleSelection`
 
 @param YES The grid view allows multiple item selection with mouse drag.
 @param NO  The grid view don't allow multiple item selection with mouse drag.
 */
@property (nonatomic, assign) BOOL allowsMultipleSelectionWithDrag;

/**
 ...
 */
@property (nonatomic, assign) BOOL useSelectionRing;

/**
 ...
 */
@property (nonatomic, assign) BOOL useHover;

/**
 `NSMenu` to use when an item or the selected items are right clicked
 */
@property (nonatomic, assign) IBOutlet NSMenu *itemContextMenu;
/**
 Returns an array of the selected `SFGridViewSelectItem` items.
 */
- (NSArray *)selectedItems;

/**
 Returns an index set of the selected items
 */
- (NSIndexSet*)selectedIndexes;

#pragma mark - Managing the Content
/** @name  Managing the Content */

/**
 Returns the number of currently visible items of `SFGridView`.
 
 The returned value of this method is subject to continous variation. It depends on the actual size of its view and will be calculated in realtime.
 */
- (NSUInteger)numberOfVisibleItems;


/**
 Reloads all the items on the grid from the data source
 */
- (void)reloadData;
- (void)reloadDataAnimated:(BOOL)animated;

- (NSRect)rectForItemAtIndex:(NSUInteger)index;

@end
