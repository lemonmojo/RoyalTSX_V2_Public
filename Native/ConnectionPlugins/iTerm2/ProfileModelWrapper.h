//
//  ProfileModelWrapper.h
//  iTerm
//
//  Created by George Nachman on 1/9/12.
//

#import <Foundation/Foundation.h>
#import "ProfileModel.h"
#import "ProfileTableRow.h"

// This is an intermediate model that wraps ProfileModel and allows
// each BookmarkListView to have a different ordering of bookmarks.
// It represents bookmarks are ProfileTableRow objects which have a
// key-value coding and can be sorted by the columns relevant to
// BookmarkListView.
@interface ProfileModelWrapper : NSObject
{
    ProfileModel* underlyingModel;
    NSMutableArray* bookmarks;
    NSMutableString* filter;
    NSArray* sortDescriptors;
}

- (id)initWithModel:(ProfileModel*)model;
- (void)dealloc;
- (void)setSortDescriptors:(NSArray*)newSortDescriptors;
- (NSArray*)sortDescriptors;

// Cause the underlying model to have the visible bookmarks in the same order as
// they appear here. Only bookmarks matching the filter are pushed.
- (void)pushOrderToUnderlyingModel;

// Sort the local representation according to sort descriptors set with setSortDescriptors.
- (void)sort;

// These functions take the filter (set with setFilter) into account with respect to indices.
- (int)numberOfBookmarks;
- (ProfileTableRow*)profileTableRowAtIndex:(int)index;
- (Profile*)profileAtIndex:(int)index;
- (int)indexOfProfileWithGuid:(NSString*)guid;
- (void)moveBookmarkWithGuid:(NSString*)guid toIndex:(int)index;

- (ProfileModel*)underlyingModel;

// Copy bookmarks matchin the filter from the underlying model.
- (void)sync;

// Show only bookmarks matching a search query 'filter'.
- (void)setFilter:(NSString*)newFilter;

@end
