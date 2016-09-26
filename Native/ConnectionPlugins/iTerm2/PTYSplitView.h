//
//  PTYSplitView.h
//  iTerm
//
//  Created by George Nachman on 12/10/11.
//

#import <AppKit/AppKit.h>
#import "FutureMethods.h"

@class PTYSplitView;

@protocol PTYSplitViewDelegate<NSSplitViewDelegate>

- (void)splitView:(PTYSplitView *)splitView
     draggingDidEndOfSplit:(int)clickedOnSplitterIndex
                    pixels:(NSSize)changePx;

- (void)splitView:(PTYSplitView *)splitView draggingWillBeginOfSplit:(int)splitterIndex;

@end

/* This extends NSSplitView by adding a delegate method that's called when
 * dragging a splitter finishes. */
@interface PTYSplitView : NSSplitView

- (NSObject<PTYSplitViewDelegate> *)delegate;
- (void)setDelegate:(NSObject<PTYSplitViewDelegate> *)delegate;

@end
