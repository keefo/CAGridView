//
//  UIGridView.m
//  UIKit
//
//  Created by Xu Lian on 2015-05-13.
//
//

#import "UIGridView.h"
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSEvent.h>
#import "UIColor.h"
#import "UITouch.h"

#import "UIGridViewSection.h"
#import "UIGridViewSectionLabel.h"
#import "UIScreenAppKitIntegration.h"
#import "UIWindow.h"
#import "UIKitView.h"
#import "UIApplication+UIPrivate.h"
#import "NSIndexPath+UIGridView.h"

// http://stackoverflow.com/questions/235120/whats-the-UIGridView-index-magnifying-glass-character
NSString *const UIGridViewIndexSearch = @"{search}";

const CGFloat _UIGridViewDefaultRowHeight = 90;

@interface UIGridView ()
{
    UIGridViewSection *_fixedSectionHeader;
}
- (void)_setNeedsReload;
@end


@implementation UIGridView

@synthesize style=_style, dataSource=_dataSource, rowHeight=_rowHeight;
@synthesize tableHeaderView=_tableHeaderView, tableFooterView=_tableFooterView, allowsSelection=_allowsSelection, editing=_editing;
@synthesize sectionFooterHeight=_sectionFooterHeight, sectionHeaderHeight=_sectionHeaderHeight;
@synthesize allowsSelectionDuringEditing=_allowsSelectionDuringEditing, backgroundView=_backgroundView;
@dynamic delegate;

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame style:UIGridViewStylePlain];
}

- (id)initWithFrame:(CGRect)frame style:(UIGridViewStyle)theStyle
{
    if ((self=[super initWithFrame:frame])) {
        
        _style = theStyle;
        _cachedCells = [[NSMutableDictionary alloc] init];
        _sections = [[NSMutableArray alloc] init];
        _reusableCells = [[NSMutableSet alloc] init];
        
        self.separatorColor = [UIColor colorWithRed:.88f green:.88f blue:.88f alpha:1];
        self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.showsHorizontalScrollIndicator = NO;
        self.allowsSelection = YES;
        self.allowsSelectionDuringEditing = NO;
        self.sectionHeaderHeight = self.sectionFooterHeight = 22;
        self.alwaysBounceVertical = YES;
        
        if (_style == UIGridViewStylePlain) {
            self.backgroundColor = [UIColor whiteColor];
        }
        
        [self _setNeedsReload];
    }
    return self;
}

- (void)dealloc
{
    [_selectedRow release];
    [_highlightedRow release];
    [_tableFooterView release];
    [_tableHeaderView release];
    [_cachedCells release];
    [_sections release];
    [_reusableCells release];
    [_fixedSectionHeader release];
    [super dealloc];
}

- (void)setFixSectionHeader:(BOOL)fixSectionHeader
{
    _fixSectionHeader = fixSectionHeader;
    if (_fixSectionHeader) {
        _fixedSectionHeader = [[UIGridViewSection alloc] init];
        _fixedSectionHeader.headerView = [UIGridViewSectionLabel sectionLabelWithTitle:@""];
        _fixedSectionHeader.headerView.frame = CGRectMake(0, 0, self.bounds.size.width, 50);
        [self addSubview:_fixedSectionHeader.headerView];
    }
    else{
        [_fixedSectionHeader.headerView removeFromSuperview];
        [_fixedSectionHeader release];
        _fixedSectionHeader = nil;
    }
}

- (void)setDataSource:(id<UIGridViewDataSource>)newSource
{
    _dataSource = newSource;
    
    _dataSourceHas.numberOfSectionsInTableView = [_dataSource respondsToSelector:@selector(numberOfSectionsInGridView:)];
    _dataSourceHas.titleForHeaderInSection = [_dataSource respondsToSelector:@selector(gridView:titleForHeaderInSection:)];
    _dataSourceHas.titleForFooterInSection = [_dataSource respondsToSelector:@selector(gridView:titleForFooterInSection:)];
    _dataSourceHas.commitEditingStyle = [_dataSource respondsToSelector:@selector(gridView:commitEditingStyle:forRowAtIndexPath:)];
    _dataSourceHas.canEditRowAtIndexPath = [_dataSource respondsToSelector:@selector(gridView:canEditRowAtIndexPath:)];
    
    [self _setNeedsReload];
}

- (void)setDelegate:(id<UIGridViewDelegate>)newDelegate
{
    [super setDelegate:newDelegate];
    
    _delegateHas.heightForHeaderInSection = [_delegate respondsToSelector:@selector(gridView:heightForHeaderInSection:)];
    _delegateHas.heightForFooterInSection = [_delegate respondsToSelector:@selector(gridView:heightForFooterInSection:)];
    _delegateHas.viewForHeaderInSection = [_delegate respondsToSelector:@selector(gridView:viewForHeaderInSection:)];
    _delegateHas.viewForFooterInSection = [_delegate respondsToSelector:@selector(gridView:viewForFooterInSection:)];
    _delegateHas.willSelectRowAtIndexPath = [_delegate respondsToSelector:@selector(gridView:willSelectRowAtIndexPath:)];
    _delegateHas.didSelectRowAtIndexPath = [_delegate respondsToSelector:@selector(gridView:didSelectRowAtIndexPath:)];
    _delegateHas.willDeselectRowAtIndexPath = [_delegate respondsToSelector:@selector(gridView:willDeselectRowAtIndexPath:)];
    _delegateHas.didDeselectRowAtIndexPath = [_delegate respondsToSelector:@selector(gridView:didDeselectRowAtIndexPath:)];
    _delegateHas.willBeginEditingRowAtIndexPath = [_delegate respondsToSelector:@selector(gridView:willBeginEditingRowAtIndexPath:)];
    _delegateHas.didEndEditingRowAtIndexPath = [_delegate respondsToSelector:@selector(gridView:didEndEditingRowAtIndexPath:)];
    _delegateHas.titleForDeleteConfirmationButtonForRowAtIndexPath = [_delegate respondsToSelector:@selector(gridView:titleForDeleteConfirmationButtonForRowAtIndexPath:)];
}

- (void)setRowHeight:(CGFloat)newHeight
{
    _rowHeight = newHeight;
    [self setNeedsLayout];
}

- (void)_updateSectionsCache
{
    // uses the dataSource to rebuild the cache.
    // if there's no dataSource, this can't do anything else.
    // note that I'm presently caching and hanging on to views and titles for section headers which is something
    // the real UIKit appears to fetch more on-demand than this. so far this has not been a problem.
    
    // remove all previous section header/footer views
    for (UIGridViewSection *previousSectionRecord in _sections) {
        [previousSectionRecord.headerView removeFromSuperview];
        [previousSectionRecord.footerView removeFromSuperview];
    }
    
    // clear the previous cache
    [_sections removeAllObjects];
    
    if (_dataSource) {
        // compute the heights/offsets of everything
        const CGFloat defaultRowHeight = _rowHeight ?: _UIGridViewDefaultRowHeight;
        const NSInteger numberOfSections = [self numberOfSections];
        for (NSInteger section=0; section<numberOfSections; section++) {
            const NSInteger numberOfItemsInSection = [self numberOfItemsInSection:section];
            
            UIGridViewSection *sectionRecord = [[UIGridViewSection alloc] init];
            sectionRecord.headerView = _delegateHas.viewForHeaderInSection? [self.delegate gridView:self viewForHeaderInSection:section] : nil;
            sectionRecord.footerView = _delegateHas.viewForFooterInSection? [self.delegate gridView:self viewForFooterInSection:section] : nil;
            sectionRecord.headerTitle = _dataSourceHas.titleForHeaderInSection? [self.dataSource gridView:self titleForHeaderInSection:section] : nil;
            sectionRecord.footerTitle = _dataSourceHas.titleForFooterInSection? [self.dataSource gridView:self titleForFooterInSection:section] : nil;
            
            // make a default section header view if there's a title for it and no overriding view
            if (!sectionRecord.headerView && sectionRecord.headerTitle) {
                sectionRecord.headerView = [UIGridViewSectionLabel sectionLabelWithTitle:sectionRecord.headerTitle];
            }
            
            // make a default section footer view if there's a title for it and no overriding view
            if (!sectionRecord.footerView && sectionRecord.footerTitle) {
                sectionRecord.footerView = [UIGridViewSectionLabel sectionLabelWithTitle:sectionRecord.footerTitle];
            }
            
            // if there's a view, then we need to set the height, otherwise it's going to be zero
            if (sectionRecord.headerView) {
                [self addSubview:sectionRecord.headerView];
                sectionRecord.headerHeight = _delegateHas.heightForHeaderInSection? [self.delegate gridView:self heightForHeaderInSection:section] : _sectionHeaderHeight;
            } else {
                sectionRecord.headerHeight = 0;
            }
            
            if (sectionRecord.footerView) {
                [self addSubview:sectionRecord.footerView];
                sectionRecord.footerHeight = _delegateHas.heightForFooterInSection? [self.delegate gridView:self heightForFooterInSection:section] : _sectionFooterHeight;
            } else {
                sectionRecord.footerHeight = 0;
            }
            
            NSInteger numberofrows = [self numberOfRowsInSection:section];
            
            CGFloat rowHeight = numberofrows*defaultRowHeight;
            CGFloat totalRowsHeight = rowHeight;
            
            sectionRecord.rowsHeight = totalRowsHeight;
            [sectionRecord setNumberOfRows:numberOfItemsInSection setNumberOfItems:numberOfItemsInSection withHeights:totalRowsHeight];
          
            [_sections addObject:sectionRecord];
            [sectionRecord release];
        }
    }
}

- (void)_updateSectionsCacheIfNeeded
{
    // if there's a cache already in place, this doesn't do anything,
    // otherwise calls _updateSectionsCache.
    // this is called from _setContentSize and other places that require access
    // to the section caches (mostly for size-related information)
    
    if ([_sections count] == 0) {
        [self _updateSectionsCache];
    }
}

- (void)_setContentSize
{
    // first calls _updateSectionsCacheIfNeeded, then sets the scroll view's size
    // taking into account the size of the header, footer, and all rows.
    // should be called by reloadData, setFrame, header/footer setters.
    
    [self _updateSectionsCacheIfNeeded];
    
    CGFloat height = _tableHeaderView? _tableHeaderView.frame.size.height : 0;
    
    for (UIGridViewSection *section in _sections) {
        height += [section sectionHeight];
    }
    
    if (_tableFooterView) {
        height += _tableFooterView.frame.size.height;
    }
    
    self.contentSize = CGSizeMake(0,height);
}

- (void)_layoutTableView
{
    // lays out headers and rows that are visible at the time. this should also do cell
    // dequeuing and keep a list of all existing cells that are visible and those
    // that exist but are not visible and are reusable
    // if there's no section cache, no rows will be laid out but the header/footer will (if any).
    
    const CGSize boundsSize = self.bounds.size;
    const CGFloat contentOffset = self.contentOffset.y;
    const CGRect visibleBounds = CGRectMake(0,contentOffset,boundsSize.width,boundsSize.height);
    CGFloat tableHeight = 0;
    
    if (_tableHeaderView) {
        CGRect tableHeaderFrame = _tableHeaderView.frame;
        tableHeaderFrame.origin = CGPointZero;
        tableHeaderFrame.size.width = boundsSize.width;
        _tableHeaderView.frame = tableHeaderFrame;
        tableHeight += tableHeaderFrame.size.height;
    }
    
    // layout sections and rows
    NSMutableDictionary *availableCells = [_cachedCells mutableCopy];
    const NSInteger numberOfSections = [_sections count];
    [_cachedCells removeAllObjects];
    UIGridViewSection *firstSectionRecord = nil;
    UIGridViewSection *secondSectionRecord = nil;
    
    for (NSInteger section=0; section<numberOfSections; section++) {
        CGRect sectionRect = [self rectForSection:section];
        tableHeight += sectionRect.size.height;
        if (CGRectIntersectsRect(sectionRect, visibleBounds)) {
            
            const CGRect headerRect = [self rectForHeaderInSection:section];
            const CGRect footerRect = [self rectForFooterInSection:section];
            UIGridViewSection *sectionRecord = [_sections objectAtIndex:section];
            const NSInteger numberOfRows = sectionRecord.numberOfRows;
            const NSInteger numberOfItems = sectionRecord.numberOfItems;
            
            if (firstSectionRecord==nil) {
                firstSectionRecord = sectionRecord;
            }
            else if(secondSectionRecord==nil){
                secondSectionRecord = sectionRecord;
            }
            
            if (sectionRecord.headerView) {
                sectionRecord.headerView.frame = headerRect;
            }
            
            if (sectionRecord.footerView) {
                sectionRecord.footerView.frame = footerRect;
            }
            
            for (NSInteger index=0; index<numberOfItems; index++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForIndex:index inSection:section];
                CGRect itemect = [self rectForItemAtIndex:indexPath.index andSection:indexPath.section];
                if (CGRectIntersectsRect(itemect,visibleBounds) && itemect.size.height > 0) {
                    UIGridViewCell *cell = [availableCells objectForKey:indexPath] ?: [self.dataSource gridView:self cellForRowAtIndexPath:indexPath];
                    if (cell) {
                        [_cachedCells setObject:cell forKey:indexPath];
                        [availableCells removeObjectForKey:indexPath];
                        cell.highlighted = [_highlightedRow isEqual:indexPath];
                        cell.selected = [_selectedRow isEqual:indexPath];
                        cell.frame = itemect;
                        cell.backgroundColor = self.backgroundColor;
                        [self addSubview:cell];
                    }
                }
            }
        }
    }
    
    // remove old cells, but save off any that might be reusable
    for (UIGridViewCell *cell in [availableCells allValues]) {
        if (cell.reuseIdentifier) {
            [_reusableCells addObject:cell];
        } else {
            [cell removeFromSuperview];
        }
    }
    
    // non-reusable cells should end up dealloced after at this point, but reusable ones live on in _reusableCells.
    [availableCells release];
    
    // now make sure that all available (but unused) reusable cells aren't on screen in the visible area.
    // this is done becaue when resizing a table view by shrinking it's height in an animation, it looks better. The reason is that
    // when an animation happens, it sets the frame to the new (shorter) size and thus recalcuates which cells should be visible.
    // If it removed all non-visible cells, then the cells on the bottom of the table view would disappear immediately but before
    // the frame of the table view has actually animated down to the new, shorter size. So the animation is jumpy/ugly because
    // the cells suddenly disappear instead of seemingly animating down and out of view like they should. This tries to leave them
    // on screen as long as possible, but only if they don't get in the way.
    NSArray* allCachedCells = [_cachedCells allValues];
    for (UIGridViewCell *cell in _reusableCells) {
        if (CGRectIntersectsRect(cell.frame,visibleBounds) && ![allCachedCells containsObject: cell]) {
            [cell removeFromSuperview];
        }
    }
    
    if (_tableFooterView) {
        CGRect tableFooterFrame = _tableFooterView.frame;
        tableFooterFrame.origin = CGPointMake(0,tableHeight);
        tableFooterFrame.size.width = boundsSize.width;
        _tableFooterView.frame = tableFooterFrame;
    }
    
    if(_fixedSectionHeader){
        int offset = 0;
        if (_tableHeaderView) {
            offset = _tableHeaderView.bounds.size.height;
        }
        if(contentOffset>offset && firstSectionRecord){
            
            CGRect tableHeaderFrame = _tableHeaderView.frame;
            tableHeaderFrame.origin = CGPointMake(0, contentOffset);
            tableHeaderFrame.size.width = boundsSize.width;
            tableHeaderFrame.size.height = _sectionHeaderHeight;
            
            if(NSIntersectsRect(secondSectionRecord.headerView.frame, tableHeaderFrame)){
                tableHeaderFrame.origin.y -= abs(contentOffset-(secondSectionRecord.headerView.frame.origin.y-secondSectionRecord.headerView.frame.size.height));
            }
            
            _fixedSectionHeader.headerView.frame = tableHeaderFrame;
            [_fixedSectionHeader setHeaderTitleAndLabel:firstSectionRecord.headerTitle];
            [self bringSubviewToFront:_fixedSectionHeader.headerView];
            [_fixedSectionHeader.headerView setHidden:NO];
        }
        else{
            [_fixedSectionHeader.headerView setHidden:YES];
        }
    }
}

- (CGRect)_CGRectFromVerticalOffset:(CGFloat)offset height:(CGFloat)height
{
    return CGRectMake(0,offset,self.bounds.size.width,height);
}

- (CGFloat)_offsetForSection:(NSInteger)index
{
    CGFloat offset = _tableHeaderView? _tableHeaderView.frame.size.height : 0;
    
    for (NSInteger s=0; s<index; s++) {
        offset += [[_sections objectAtIndex:s] sectionHeight];
    }
    
    return offset;
}

- (CGRect)rectForSection:(NSInteger)section
{
    [self _updateSectionsCacheIfNeeded];
    return [self _CGRectFromVerticalOffset:[self _offsetForSection:section] height:[[_sections objectAtIndex:section] sectionHeight]];
}

- (CGRect)rectForHeaderInSection:(NSInteger)section
{
    [self _updateSectionsCacheIfNeeded];
    return [self _CGRectFromVerticalOffset:[self _offsetForSection:section] height:[[_sections objectAtIndex:section] headerHeight]];
}

- (CGRect)rectForFooterInSection:(NSInteger)section
{
    [self _updateSectionsCacheIfNeeded];
    UIGridViewSection *sectionRecord = [_sections objectAtIndex:section];
    CGFloat offset = [self _offsetForSection:section];
    offset += sectionRecord.headerHeight;
    offset += sectionRecord.rowsHeight;
    return [self _CGRectFromVerticalOffset:offset height:sectionRecord.footerHeight];
}

- (CGRect)rectForItemAtIndex:(NSInteger)index andSection:(NSInteger)section
{
    [self _updateSectionsCacheIfNeeded];
    if (section < [_sections count]) {
        UIGridViewSection *sectionRecord = [_sections objectAtIndex:section];
        if (index < sectionRecord.numberOfItems) {
            
            const CGFloat defaultRowHeight = _rowHeight ?: _UIGridViewDefaultRowHeight;
            NSInteger numberOfColumns = [self numberOfColumns];
            CGFloat itemWidth = ceil(self.bounds.size.width/numberOfColumns);
            CGFloat offset = [self _offsetForSection:section] + sectionRecord.headerHeight;
            
            return CGRectMake(itemWidth * (index % numberOfColumns), offset + ((int)ceil(index / numberOfColumns)*defaultRowHeight), itemWidth, defaultRowHeight);
        }
    }
    return CGRectZero;
}

/*
- (CGRect)rectForIndexAtIndexPath:(NSIndexPath *)indexPath
{
    [self _updateSectionsCacheIfNeeded];
    
    if (indexPath && indexPath.section < [_sections count]) {
        UIGridViewSection *sectionRecord = [_sections objectAtIndex:indexPath.section];
        const NSUInteger row = indexPath.row;
        const CGFloat defaultRowHeight = _rowHeight ?: _UIGridViewDefaultRowHeight;
        
        if (row < sectionRecord.numberOfRows) {
            
            CGFloat offset = [self _offsetForSection:indexPath.section];
            
            offset += sectionRecord.headerHeight;
            offset += sectionRecord.rowsHeight;
            
            return [self _CGRectFromVerticalOffset:offset height:defaultRowHeight];
        }
    }
    
    return CGRectZero;
}
*/

- (void) beginUpdates
{
}

- (void)endUpdates
{
}

- (UIGridViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // this is allowed to return nil if the cell isn't visible and is not restricted to only returning visible cells
    // so this simple call should be good enough.
    return [_cachedCells objectForKey:indexPath];
}


- (NSArray *)indexPathsForItemsInRect:(CGRect)rect
{
    // This needs to return the index paths even if the cells don't exist in any caches or are not on screen
    // For now I'm assuming the cells stretch all the way across the view. It's not clear to me if the real
    // implementation gets anal about this or not (haven't tested it).
    
    [self _updateSectionsCacheIfNeeded];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    const NSInteger numberOfSections = [_sections count];
    const NSInteger numberOfColumns = [self numberOfColumns];
    const CGFloat columnWidth = self.bounds.size.width/numberOfColumns;
    const CGFloat defaultRowHeight = _rowHeight ?: _UIGridViewDefaultRowHeight;
    CGFloat offset = _tableHeaderView? _tableHeaderView.frame.size.height : 0;
    
    for (NSInteger section=0; section<numberOfSections; section++) {
        UIGridViewSection *sectionRecord = [_sections objectAtIndex:section];
        
        CGFloat rowsHeight = sectionRecord.rowsHeight;
        const NSInteger numberOfRows = sectionRecord.numberOfRows;
        const NSInteger numberOfItems = sectionRecord.numberOfItems;
        
        offset += sectionRecord.headerHeight;
        
        if (offset + sectionRecord.rowsHeight >= rect.origin.y) {
            
            for (NSInteger idx=0; idx<numberOfItems; idx++) {
                
                CGRect simpleItemRect = [self rectForItemAtIndex:idx andSection:section];
                
                if (CGRectIntersectsRect(rect,simpleItemRect)) {
                    [results addObject:[NSIndexPath indexPathForIndex:idx inSection:section]];
                } else if (simpleItemRect.origin.y > rect.origin.y+rect.size.height) {
                    break;	// don't need to find anything else.. we are past the end
                }
                
                offset += defaultRowHeight*(ceil((idx+1)/numberOfColumns)*defaultRowHeight);
            }
            
        } else {
            offset += sectionRecord.rowsHeight;
        }
        
        offset += sectionRecord.footerHeight;
    }
    
    return [results autorelease];
}

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    NSArray *paths = [self indexPathsForItemsInRect:CGRectMake(point.x,point.y,1,1)];
    return ([paths count] > 0)? [paths objectAtIndex:0] : nil;
}

- (NSArray *)indexPathsForVisibleRows
{
    [self _layoutTableView];
    
    NSMutableArray *indexes = [NSMutableArray arrayWithCapacity:[_cachedCells count]];
    const CGRect bounds = self.bounds;
    
    // Special note - it's unclear if UIKit returns these in sorted order. Because we're assuming that visibleCells returns them in order (top-bottom)
    // and visibleCells uses this method, I'm going to make the executive decision here and assume that UIKit probably does return them sorted - since
    // there's nothing warning that they aren't. :)
    
    for (NSIndexPath *indexPath in [[_cachedCells allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        if (CGRectIntersectsRect(bounds,[self rectForItemAtIndex:indexPath.index andSection:indexPath.section])) {
            [indexes addObject:indexPath];
        }
    }
    
    return indexes;
}

- (NSArray *)visibleCells
{
    NSMutableArray *cells = [[[NSMutableArray alloc] init] autorelease];
    for (NSIndexPath *index in [self indexPathsForVisibleRows]) {
        UIGridViewCell *cell = [self cellForRowAtIndexPath:index];
        if (cell) {
            [cells addObject:cell];
        }
    }
    return cells;
}

- (void)setTableHeaderView:(UIView *)newHeader
{
    if (newHeader != _tableHeaderView) {
        [_tableHeaderView removeFromSuperview];
        [_tableHeaderView release];
        _tableHeaderView = [newHeader retain];
        [self _setContentSize];
        [self addSubview:_tableHeaderView];
    }
}

- (void)setTableFooterView:(UIView *)newFooter
{
    if (newFooter != _tableFooterView) {
        [_tableFooterView removeFromSuperview];
        [_tableFooterView release];
        _tableFooterView = [newFooter retain];
        [self _setContentSize];
        [self addSubview:_tableFooterView];
    }
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    if (_backgroundView != backgroundView) {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
        _backgroundView = [backgroundView retain];
        [self insertSubview:_backgroundView atIndex:0];
    }
}

- (NSInteger)numberOfColumns
{
    CGFloat defaultRowHeight = _rowHeight ?: _UIGridViewDefaultRowHeight;
    if (self.bounds.size.width<defaultRowHeight) {
        defaultRowHeight = self.bounds.size.width;
    }
    int numberofcolumns = floor(self.bounds.size.width/defaultRowHeight);
    if(numberofcolumns<1)
        numberofcolumns=1;
    return numberofcolumns;
}

- (NSInteger)numberOfSections
{
    if (_dataSourceHas.numberOfSectionsInTableView) {
        return [self.dataSource numberOfSectionsInGridView:self];
    } else {
        return 1;
    }
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    NSInteger num = [self numberOfItemsInSection:section];
    NSInteger col = [self numberOfColumns];
    return ceil((double)num/(double)col);
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource gridView:self numberOfItemsInSection:section];
}

- (void)reloadData
{
    // clear the caches and remove the cells since everything is going to change
    [[_cachedCells allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_reusableCells makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_reusableCells removeAllObjects];
    [_cachedCells removeAllObjects];
    
    // clear prior selection
    [_selectedRow release];
    _selectedRow = nil;
    [_highlightedRow release];
    _highlightedRow = nil;
    
    // trigger the section cache to be repopulated
    [self _updateSectionsCache];
    [self _setContentSize];
    
    _needsReload = NO;
}

- (void)_reloadDataIfNeeded
{
    if (_needsReload) {
        [self reloadData];
    }
}

- (void)_setNeedsReload
{
    _needsReload = YES;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    _backgroundView.frame = self.bounds;
    [self _reloadDataIfNeeded];
    [self _layoutTableView];
    [super layoutSubviews];
}

- (void)setFrame:(CGRect)frame
{
    const CGRect oldFrame = self.frame;
    if (!CGRectEqualToRect(oldFrame,frame)) {
        [super setFrame:frame];
        
        if (oldFrame.size.width != frame.size.width) {
            [self _updateSectionsCache];
        }
        
        [self _setContentSize];
    }
}

- (NSIndexPath *)indexPathForSelectedRow
{
    return [[_selectedRow retain] autorelease];
}

- (NSIndexPath *)indexPathForCell:(UIGridViewCell *)cell
{
    for (NSIndexPath *index in [_cachedCells allKeys]) {
        if ([_cachedCells objectForKey:index] == cell) {
            return [[index retain] autorelease];
        }
    }
    
    return nil;
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (indexPath && [indexPath isEqual:_selectedRow]) {
        [self cellForRowAtIndexPath:_selectedRow].selected = NO;
        [_selectedRow release];
        _selectedRow = nil;
    }
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UIGridViewScrollPosition)scrollPosition
{
    // unlike the other methods that I've tested, the real UIKit appears to call reload during selection if the table hasn't been reloaded
    // yet. other methods all appear to rebuild the section cache "on-demand" but don't do a "proper" reload. for the sake of attempting
    // to maintain a similar delegate and dataSource access pattern to the real thing, I'll do it this way here. :)
    [self _reloadDataIfNeeded];
    
    if (![_selectedRow isEqual:indexPath]) {
        [self deselectRowAtIndexPath:_selectedRow animated:animated];
        [_selectedRow release];
        _selectedRow = [indexPath retain];
        [self cellForRowAtIndexPath:_selectedRow].selected = YES;
    }
    
    // I did not verify if the real UIKit will still scroll the selection into view even if the selection itself doesn't change.
    // this behavior was useful for Ostrich and seems harmless enough, so leaving it like this for now.
    [self scrollToRowAtIndexPath:_selectedRow atScrollPosition:scrollPosition animated:animated];
}

- (void)_scrollRectToVisible:(CGRect)aRect atScrollPosition:(UIGridViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    if (!CGRectIsNull(aRect) && aRect.size.height > 0) {
        // adjust the rect based on the desired scroll position setting
        switch (scrollPosition) {
            case UIGridViewScrollPositionNone:
                break;
                
            case UIGridViewScrollPositionTop:
                aRect.size.height = self.bounds.size.height;
                break;
                
            case UIGridViewScrollPositionMiddle:
                aRect.origin.y -= (self.bounds.size.height / 2.f) - aRect.size.height;
                aRect.size.height = self.bounds.size.height;
                break;
                
            case UIGridViewScrollPositionBottom:
                aRect.origin.y -= self.bounds.size.height - aRect.size.height;
                aRect.size.height = self.bounds.size.height;
                break;
        }
        
        [self scrollRectToVisible:aRect animated:animated];
    }
}

- (void)scrollToNearestSelectedRowAtScrollPosition:(UIGridViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    NSIndexPath *idx = [self indexPathForSelectedRow];
    [self _scrollRectToVisible:[self rectForItemAtIndex:idx.row andSection:idx.section] atScrollPosition:scrollPosition animated:animated];
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UIGridViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    [self _scrollRectToVisible:[self rectForItemAtIndex:indexPath.index andSection:indexPath.section] atScrollPosition:scrollPosition animated:animated];
}

- (UIGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    for (UIGridViewCell *cell in _reusableCells) {
        if ([cell.reuseIdentifier isEqualToString:identifier]) {
            [cell retain];
            [_reusableCells removeObject:cell];
            [cell prepareForReuse];
            return [cell autorelease];
        }
    }
    
    return nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
    _editing = editing;
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UIGridViewRowAnimation)animation
{
    [self reloadData];
}

- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UIGridViewRowAnimation)animation
{
    [self reloadData];
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UIGridViewRowAnimation)animation
{
    [self reloadData];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UIGridViewRowAnimation)animation
{
    [self reloadData];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_highlightedRow) {
        UITouch *touch = [touches anyObject];
        const CGPoint location = [touch locationInView:self];
        
        _highlightedRow = [[self indexPathForItemAtPoint:location] retain];
        [self cellForRowAtIndexPath:_highlightedRow].highlighted = YES;
    }
    
    if (_highlightedRow) {
        NSIndexPath *selectedRow = [self indexPathForSelectedRow];
        
        if (selectedRow) {
            NSIndexPath *rowToDeselect = selectedRow;
            
            if (_delegateHas.willDeselectRowAtIndexPath) {
                rowToDeselect = [_delegate gridView:self willDeselectRowAtIndexPath:rowToDeselect];
            }
            
            [self deselectRowAtIndexPath:rowToDeselect animated:NO];
            
            if (_delegateHas.didDeselectRowAtIndexPath) {
                [_delegate gridView:self didDeselectRowAtIndexPath:rowToDeselect];
            }
        }
        
        NSIndexPath *rowToSelect = _highlightedRow;
        
        if (_delegateHas.willSelectRowAtIndexPath) {
            rowToSelect = [_delegate gridView:self willSelectRowAtIndexPath:rowToSelect];
        }
        
        [self cellForRowAtIndexPath:_highlightedRow].highlighted = NO;
        [self selectRowAtIndexPath:rowToSelect animated:NO scrollPosition:UIGridViewScrollPositionNone];
        
        if (_delegateHas.didSelectRowAtIndexPath) {
            [_delegate gridView:self didSelectRowAtIndexPath:rowToSelect];
        }
        
        [_highlightedRow release];
        _highlightedRow = nil;
    }


}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // this isn't quite how iOS seems to do it, but I think it makes sense on OSX
    if (_highlightedRow) {
        UITouch *touch = [touches anyObject];
        const CGPoint location = [touch locationInView:self];
        
        if (!CGRectContainsPoint([self rectForItemAtIndex:_highlightedRow.row andSection:_highlightedRow.section], location)) {
            [self cellForRowAtIndexPath:_highlightedRow].highlighted = NO;
            [_highlightedRow release];
            _highlightedRow = nil;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    /*
    if (_highlightedRow) {
        NSIndexPath *selectedRow = [self indexPathForSelectedRow];
        
        if (selectedRow) {
            NSIndexPath *rowToDeselect = selectedRow;
            
            if (_delegateHas.willDeselectRowAtIndexPath) {
                rowToDeselect = [_delegate gridView:self willDeselectRowAtIndexPath:rowToDeselect];
            }
            
            [self deselectRowAtIndexPath:rowToDeselect animated:NO];
            
            if (_delegateHas.didDeselectRowAtIndexPath) {
                [_delegate gridView:self didDeselectRowAtIndexPath:rowToDeselect];
            }
        }
        
        NSIndexPath *rowToSelect = _highlightedRow;
        
        if (_delegateHas.willSelectRowAtIndexPath) {
            rowToSelect = [_delegate gridView:self willSelectRowAtIndexPath:rowToSelect];
        }
        
        [self cellForRowAtIndexPath:_highlightedRow].highlighted = NO;
        [self selectRowAtIndexPath:rowToSelect animated:NO scrollPosition:UIGridViewScrollPositionNone];
        
        if (_delegateHas.didSelectRowAtIndexPath) {
            [_delegate gridView:self didSelectRowAtIndexPath:rowToSelect];
        }
        
        [_highlightedRow release];
        _highlightedRow = nil;
    }*/
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_highlightedRow) {
        [self cellForRowAtIndexPath:_highlightedRow].highlighted = NO;
        [_highlightedRow release];
        _highlightedRow = nil;
    }
}

- (BOOL)_canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // it's YES by default until the dataSource overrules
    return _dataSourceHas.commitEditingStyle && (!_dataSourceHas.canEditRowAtIndexPath || [_dataSource gridView:self canEditRowAtIndexPath:indexPath]);
}

- (void)_beginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _canEditRowAtIndexPath:indexPath]) {
        self.editing = YES;
        
        if (_delegateHas.willBeginEditingRowAtIndexPath) {
            [_delegate gridView:self willBeginEditingRowAtIndexPath:indexPath];
        }
        
        // deferring this because it presents a modal menu and that's what we do everywhere else in Chameleon
        [self performSelector:@selector(_showEditMenuForRowAtIndexPath:) withObject:indexPath afterDelay:0];
    }
}

- (void)_endEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        self.editing = NO;
        
        if (_delegateHas.didEndEditingRowAtIndexPath) {
            [_delegate gridView:self didEndEditingRowAtIndexPath:indexPath];
        }
    }
}

- (void)_showEditMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // re-checking for safety since _showEditMenuForRowAtIndexPath is deferred. this may be overly paranoid.
    if ([self _canEditRowAtIndexPath:indexPath]) {
        UIGridViewCell *cell = [self cellForRowAtIndexPath:indexPath];
        NSString *menuItemTitle = nil;
        
        // fetch the title for the delete menu item
        if (_delegateHas.titleForDeleteConfirmationButtonForRowAtIndexPath) {
            menuItemTitle = [_delegate gridView:self titleForDeleteConfirmationButtonForRowAtIndexPath:indexPath];
        }
        if ([menuItemTitle length] == 0) {
            menuItemTitle = @"Delete";
        }
        
        cell.highlighted = YES;
        
        NSMenuItem *theItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle action:NULL keyEquivalent:@""];
        
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        [menu setAutoenablesItems:NO];
        [menu setAllowsContextMenuPlugIns:NO];
        [menu addItem:theItem];
        
        // calculate the mouse's current position so we can present the menu from there since that's normal OSX behavior
        NSPoint mouseLocation = [NSEvent mouseLocation];
        CGPoint screenPoint = [self.window.screen convertPoint:NSPointToCGPoint(mouseLocation) fromScreen:nil];
        
        // modally present a menu with the single delete option on it, if it was selected, then do the delete, otherwise do nothing
        const BOOL didSelectItem = [menu popUpMenuPositioningItem:nil atLocation:NSPointFromCGPoint(screenPoint) inView:[self.window.screen UIKitView]];
        
        [menu release];
        [theItem release];
        
        [[UIApplication sharedApplication] _cancelTouches];
        
        if (didSelectItem) {
            [_dataSource gridView:self commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        }
        
        cell.highlighted = NO;
    }
    
    // all done
    [self _endEditingRowAtIndexPath:indexPath];
}

- (void)rightClick:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [touch locationInView:self];
    NSIndexPath *touchedRow = [self indexPathForItemAtPoint:location];
    
    // this is meant to emulate UIKit's swipe-to-delete feature on Mac by way of a right-click menu
    if (touchedRow && [self _canEditRowAtIndexPath:touchedRow]) {
        [self _beginEditingRowAtIndexPath:touchedRow];
    }
}

@end
