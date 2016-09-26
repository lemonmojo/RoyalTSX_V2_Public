//
//  MovePaneController.h
//  iTerm2
//
//  Runs the show for moving a session into a split pane.
//
//  Created by George Nachman on 8/26/11.

#import <Foundation/Foundation.h>
#import "SplitSelectionView.h"

@class PTYTab;
@class PTYSession;
@class SessionView;
@interface MovePaneController : NSObject <SplitSelectionViewDelegate> {
    // The session being moved.
    PTYSession *session_;  // weak

    BOOL dragFailed_;
    BOOL didSplit_;
}

@property (nonatomic, assign) BOOL dragFailed;
@property (nonatomic, assign) PTYSession *session;

+ (MovePaneController *)sharedInstance;
// Iniate click-to-move mode.
- (void)movePane:(PTYSession *)session;
- (void)exitMovePaneMode;
// Initiate dragging.
- (void)beginDrag:(PTYSession *)session;
- (BOOL)isMovingSession:(PTYSession *)s;
- (BOOL)dropInSession:(PTYSession *)dest
                 half:(SplitSessionHalf)half
              atPoint:(NSPoint)point;
- (BOOL)dropTab:(PTYTab *)tab
      inSession:(PTYSession *)dest
           half:(SplitSessionHalf)half
        atPoint:(NSPoint)point;

// Clears the session so that the normal drop handler (e.g., -[SessionView draggedImage:endedAt:operation:])
// doesn't do anything.
- (void)clearSession;

// Returns an autoreleased session view. Add the session view to something useful and release it.
- (SessionView *)removeAndClearSession;
- (void)moveSessionToNewWindow:(PTYSession *)movingSession
                       atPoint:(NSPoint)point;

@end
