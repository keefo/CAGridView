//
//  SFGridView.m
//  GridView
//
//  Created by Xu Lian on 2015-05-12.
//  Copyright (c) 2015 beyondcow. All rights reserved.
//

#import "SFGridView.h"
#import "SFGridItemBase.h"

NSString *const SFGridViewSelectAllItemsNotification = @"SFGridViewSelectAllItems";
NSString *const SFGridViewDeSelectAllItemsNotification = @"SFGridViewDeSelectAllItems";

NSString *const SFGridViewWillHoverItemNotification = @"SFGridViewWillHoverItem";
NSString *const SFGridViewWillUnhoverItemNotification = @"SFGridViewWillUnhoverItem";
NSString *const SFGridViewWillSelectItemNotification = @"SFGridViewWillSelectItem";
NSString *const SFGridViewDidSelectItemNotification = @"SFGridViewDidSelectItem";
NSString *const SFGridViewWillDeselectItemNotification = @"SFGridViewWillDeselectItem";
NSString *const SFGridViewDidDeselectItemNotification = @"SFGridViewDidDeselectItem";
NSString *const SFGridViewWillDeselectAllItemsNotification = @"SFGridViewWillDeselectAllItems";
NSString *const SFGridViewDidDeselectAllItemsNotification = @"SFGridViewDidDeselectAllItems";
NSString *const SFGridViewDidClickItemNotification = @"SFGridViewDidClickItem";
NSString *const SFGridViewDidDoubleClickItemNotification = @"SFGridViewDidDoubleClickItem";
NSString *const SFGridViewRightMouseButtonClickedOnItemNotification = @"SFGridViewRightMouseButtonClickedOnItem";

NSString *const SFGridViewItemKey = @"gridViewItem";
NSString *const SFGridViewItemIndexKey = @"gridViewItemIndex";
NSString *const SFGridViewSelectedItemsKey = @"SFGridViewSelectedItems";
NSString *const SFGridViewItemsIndexSetKey = @"SFGridViewItemsIndexSetKey";


@interface SFGridView () {
    
    CALayer *hostedLayer;
    NSMutableDictionary *keyedVisibleItems;
    NSMutableDictionary *reuseableItems;
    NSMutableDictionary *selectedItems;
    NSMutableDictionary *selectedItemsBySelectionFrame;
    
    NSNotificationCenter *nc;
    NSMutableArray *clickEvents;
    NSTrackingArea *gridViewTrackingArea;
    NSTimer *clickTimer;
    NSInteger lastHoveredIndex;
    NSInteger lastSelectedItemIndex;
    NSInteger numberOfItems;
    CGPoint selectionFrameInitialPoint;
    BOOL isInitialCall;
    BOOL mouseHasDragged;
    BOOL abortSelection;
    
    CGFloat _contentInset;
}
@end


@implementation SFGridView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self=[super initWithFrame:frameRect]) {
        [self setupDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}


- (void)setupDefaults {
    //create layer host view
    keyedVisibleItems = [[NSMutableDictionary alloc] init];
    reuseableItems = [[NSMutableDictionary alloc] init];
    selectedItems = [[NSMutableDictionary alloc] init];
    selectedItemsBySelectionFrame = [[NSMutableDictionary alloc] init];
    clickEvents = [NSMutableArray array];
    nc = [NSNotificationCenter defaultCenter];
    lastHoveredIndex = NSNotFound;
    lastSelectedItemIndex = NSNotFound;
    selectionFrameInitialPoint = CGPointZero;
    clickTimer = nil;
    isInitialCall = YES;
    abortSelection = NO;
    mouseHasDragged = NO;

    // properties
    _backgroundColor = [NSColor controlColor];
    _itemSize = NSMakeSize(120, 120);
 }

- (void)awakeFromNib
{
    [self setWantsLayer:YES];
    hostedLayer = [CALayer layer];
    hostedLayer.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    //hostedLayer.backgroundColor = [[NSColor redColor] CGColor];
    [self setLayer:hostedLayer];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [self.layer setFrame:self.bounds];
    [CATransaction commit];
    
//    [[self enclosingScrollView] setDrawsBackground:YES];
//    [[self enclosingScrollView] setBackgroundColor:[NSColor yellowColor]];
    
    [nc addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self.window];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor grayColor] setFill];
    NSRectFill(dirtyRect);
}

- (NSScrollView*)enclosingScrollView
{
    return [super enclosingScrollView];
}

- (void)windowDidResize:(id)d
{
    [self setFrame:self.frame];
}

- (void)setFrame:(NSRect)frameRect {
    NSRect r=[[self enclosingScrollView] frame];
    if (frameRect.size.width!=r.size.width) {
        frameRect.size.width=r.size.width;
    }
    BOOL animated = (self.frame.size.width == frameRect.size.width ? NO : YES);
    animated = NO;
    [super setFrame:frameRect];
    [self refreshGridViewAnimated:animated initialCall:YES];
}

- (void)updateVisibleRect {
    [self updateReuseableItems];
    [self updateVisibleItems];
    [self arrangeGridViewItemsAnimated:NO];
}

- (void)updateReuseableItems {

    //Do not mark items as reusable unless there are no selected items in the grid as recycling items when doing range multiselect
    if (self.selectedIndexes.count == 0) {
        NSRange visibleItemRange = [self visibleItemRange];
        
        [[keyedVisibleItems allValues] enumerateObjectsUsingBlock: ^(SFGridItemView *item, NSUInteger idx, BOOL *stop) {
            if (!NSLocationInRange(item.index, visibleItemRange) && [item isReuseable]) {
                [keyedVisibleItems removeObjectForKey:@(item.index)];
                [item removeFromSuperlayer];
                [item prepareForReuse];
                
                NSMutableSet *reuseQueue = reuseableItems[item.reuseIdentifier];
                if (reuseQueue == nil) {
                    reuseQueue = [NSMutableSet set];
                }
                [reuseQueue addObject:item];
                reuseableItems[item.reuseIdentifier] = reuseQueue;
            }
        }];
    }
    
}


- (void)updateVisibleItems {
    NSRange visibleItemRange = [self visibleItemRange];
    NSMutableIndexSet *visibleItemIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:visibleItemRange];
    
    [visibleItemIndexes removeIndexes:[self indexesForVisibleItems]];
    
    // update all visible items
    [visibleItemIndexes enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
        SFGridItemView *item = [self gridView:self itemAtIndex:idx inSection:0];
        if (item) {
            item.index = idx;
            if (isInitialCall) {
                [item setOpacity:1.0];
                [item setFrame:[self rectForItemAtIndex:idx]];
            }
            [keyedVisibleItems setObject:item forKey:@(item.index)];
            [self.layer addSublayer:item];
        }
    }];
}

- (void)arrangeGridViewItemsAnimated:(BOOL)animated {
    if ([keyedVisibleItems count] > 0) {
        if (isInitialCall) {
            isInitialCall = NO;
            if (animated) {
                
                [CATransaction begin];
                [CATransaction setValue:@(0.15) forKey:kCATransactionAnimationDuration];
                [keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, SFGridItemView *item, BOOL *stop) {
                    [item setOpacity:1.0];
                    [item setFrame:[self rectForItemAtIndex:item.index]];
                }];
                [CATransaction commit];
            }
            else{
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                [keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, SFGridItemView *item, BOOL *stop) {
                    [item setOpacity:1.0];
                    [item setFrame:[self rectForItemAtIndex:item.index]];
                }];
                [CATransaction commit];
            }
        }
        else{
            if (animated) {
                [CATransaction begin];
                [CATransaction setValue:@(0.15) forKey:kCATransactionAnimationDuration];
                [keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, SFGridItemView *item, BOOL *stop) {
                    NSRect newRect = [self rectForItemAtIndex:item.index];
                    [item setFrame:newRect];
                }];
                [CATransaction commit];
            }
            else{
                [CATransaction begin];
                [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
                [keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, SFGridItemView *item, BOOL *stop) {
                    NSRect newRect = [self rectForItemAtIndex:item.index];
                    [item setFrame:newRect];
                }];
                [CATransaction commit];
            }
        }
    }
}

- (void)refreshGridViewAnimated:(BOOL)animated initialCall:(BOOL)initialCall {
    
    isInitialCall = initialCall;
    NSScrollView *scrollView = self.enclosingScrollView;
    CGSize size = self.frame.size;
    CGFloat newHeight = [self numberOfRowsInGridView] * self.itemSize.height + _contentInset * 2;
    if (ABS(newHeight - size.height) > 1) {
        size.height = newHeight;
    }
    if (size.height<NSHeight(scrollView.frame)) {
        size.height=NSHeight(scrollView.frame);
    }
    if (size.width<NSWidth(scrollView.frame)) {
        size.width=NSWidth(scrollView.frame);
    }
    if (size.width!=self.frame.size.width || size.height!=self.frame.size.height) {
        [super setFrameSize:size];
    
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [self.layer setFrame:self.bounds];
        [CATransaction commit];
    }

    [scrollView reflectScrolledClipView:[scrollView contentView]];
    
    [self _refreshInset];
    
    __weak typeof(self) wSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wSelf _refreshInset];
        [wSelf updateReuseableItems];
        [wSelf updateVisibleItems];
        [wSelf arrangeGridViewItemsAnimated:animated];
    });

}

- (void)_refreshInset {
    _contentInset = 20;
}

- (NSRect)clippedRect {
    return [[[self enclosingScrollView] contentView] bounds];
}

- (NSRange)visibleItemRange {
    NSRect clippedRect  = [self clippedRect];
    NSUInteger columns  = [self numberOfColumnsInGridView];
    NSUInteger rows     = [self visibleRowsInGridView];
    
    NSUInteger rangeStart = 0;
    if (clippedRect.origin.y > self.itemSize.height) {
        rangeStart = (ceilf(clippedRect.origin.y / self.itemSize.height) * columns) - columns;
    }
    NSUInteger rangeLength = MIN(numberOfItems, (columns * rows) + columns);
    rangeLength = ((rangeStart + rangeLength) > numberOfItems ? numberOfItems - rangeStart : rangeLength);
    
    NSRange rangeForVisibleRect = NSMakeRange(rangeStart, rangeLength);
    return rangeForVisibleRect;
}

- (NSUInteger)numberOfColumnsInGridView {
    NSRect visibleRect  = [self clippedRect];
    NSUInteger columns = floorf((float)(NSWidth(visibleRect)-_contentInset-_contentInset) / self.itemSize.width);
    columns = (columns < 1 ? 1 : columns);
    return columns;
}

- (NSUInteger)numberOfRowsInGridView {
    NSUInteger allOverRows = ceilf((float)numberOfItems / [self numberOfColumnsInGridView]);
    return allOverRows;
}

- (NSUInteger)visibleRowsInGridView {
    NSRect visibleRect  = [self clippedRect];
    NSUInteger visibleRows = ceilf((float)NSHeight(visibleRect) / self.itemSize.height);
    return visibleRows;
}

- (NSIndexSet *)visibleIndexes {
    return [NSIndexSet indexSetWithIndexesInRange:[self visibleItemRange]];
}

- (NSIndexSet *)indexesForVisibleItems {
    __block NSMutableIndexSet *indexesForVisibleItems = [[NSMutableIndexSet alloc] init];
    [keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, SFGridItemView *item, BOOL *stop) {
        [indexesForVisibleItems addIndex:item.index];
    }];
    return indexesForVisibleItems;
}

- (NSArray *)selectedItems {
    return [selectedItems allValues];
}

- (NSIndexSet *)selectedIndexes {
    NSMutableIndexSet *mutableIndex = [NSMutableIndexSet indexSet];
    NSArray *list = [self selectedItems];
    for (SFGridItemView *gridItem in list) {
        [mutableIndex addIndex:gridItem.index];
    }
    return mutableIndex;
}

- (NSRect)rectForItemAtIndex:(NSUInteger)index {
    
    NSUInteger columns = [self numberOfColumnsInGridView];
    NSUInteger columnWidth = (NSUInteger)floor((NSWidth(self.bounds)-_contentInset-_contentInset)/columns);
    
    CGFloat x = (index % columns) * columnWidth + (int)((columnWidth-self.itemSize.width)/2.0) + _contentInset;
    CGFloat y = NSHeight(self.bounds)-_contentInset - (ceil(index/columns)) * self.itemSize.height;
    int row = ceil(index/columns)+1;
    y = NSHeight(self.bounds) - _contentInset - row * (self.itemSize.height+10);
    NSRect itemRect = NSMakeRect(x,
                                 y,
                                 self.itemSize.width,
                                 self.itemSize.height);
    
    NSLog(@"%lu %lu %@", index, row, NSStringFromRect(itemRect));
    
    return itemRect;
}

#pragma mark - Creating GridView Items

- (id)dequeueReusableItemWithIdentifier:(NSString *)identifier
{
    SFGridItemView *reusableItem = nil;
    NSMutableSet *reuseQueue = reuseableItems[identifier];
    if (reuseQueue != nil && [reuseQueue count] > 0) {
        reusableItem = [reuseQueue anyObject];
        [reuseQueue removeObject:reusableItem];
        reuseableItems[identifier] = reuseQueue;
        reusableItem.representedObject = nil;
    }
    return reusableItem;
}


#pragma mark - Reloading GridView Data

- (void)reloadData {
    [self reloadDataAnimated:NO];
}

- (void)reloadDataAnimated:(BOOL)animated {
    numberOfItems = [self gridView:self numberOfItemsInSection:0];
    [keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        [(SFGridItemBase *)obj removeFromSuperlayer];
    }];
    [keyedVisibleItems removeAllObjects];
    [reuseableItems removeAllObjects];
    [self refreshGridViewAnimated:animated initialCall:YES];
}


#pragma mark - SFGridView Delegate Calls

- (void)gridView:(SFGridView *)gridView willHoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewWillHoverItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willHoverItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView willUnhoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewWillUnhoverItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willUnhoverItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView willSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewWillSelectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willSelectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewDidSelectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didSelectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView willDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewWillDeselectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willDeselectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewDidDeselectItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didDeselectItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView willDeselectAllItems:(NSArray *)theSelectedItems {
    [nc postNotificationName:SFGridViewWillDeselectAllItemsNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:theSelectedItems forKey:SFGridViewSelectedItemsKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView willDeselectAllItems:theSelectedItems];
    }
}

- (void)gridViewDidDeselectAllItems:(SFGridView *)gridView {
    [nc postNotificationName:SFGridViewDidDeselectAllItemsNotification object:gridView userInfo:nil];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridViewDidDeselectAllItems:gridView];
    }
}

- (void)gridView:(SFGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewDidClickItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didClickItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewDidDoubleClickItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:SFGridViewItemIndexKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didDoubleClickItemAtIndex:index inSection:section];
    }
}

- (void)gridView:(SFGridView *)gridView didActivateContextMenuWithIndexes:(NSIndexSet *)indexSet inSection:(NSUInteger)section {
    [nc postNotificationName:SFGridViewRightMouseButtonClickedOnItemNotification
                      object:gridView
                    userInfo:[NSDictionary dictionaryWithObject:indexSet forKey:SFGridViewItemsIndexSetKey]];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate gridView:gridView didActivateContextMenuWithIndexes:indexSet inSection:section];
    }
}

#pragma mark - SFGridView DataSource Calls

- (NSUInteger)gridView:(SFGridView *)gridView numberOfItemsInSection:(NSInteger)section {
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource gridView:gridView numberOfItemsInSection:section];
    }
    return NSNotFound;
}

- (SFGridItemView *)gridView:(SFGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section {
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource gridView:gridView itemAtIndex:index inSection:section];
    }
    return nil;
}

- (NSUInteger)numberOfSectionsInGridView:(SFGridView *)gridView {
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource numberOfSectionsInGridView:gridView];
    }
    return NSNotFound;
}

- (NSString *)gridView:(SFGridView *)gridView titleForHeaderInSection:(NSInteger)section {
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource gridView:gridView titleForHeaderInSection:section];
    }
    return nil;
}

- (NSArray *)sectionIndexTitlesForGridView:(SFGridView *)gridView {
    if ([self.dataSource respondsToSelector:_cmd]) {
        return [self.dataSource sectionIndexTitlesForGridView:gridView];
    }
    return nil;
}


@end
