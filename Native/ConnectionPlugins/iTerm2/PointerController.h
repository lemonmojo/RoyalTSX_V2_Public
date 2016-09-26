//
//  PointerController.h
//  iTerm
//
//  Created by George Nachman on 11/7/11.
//  Copyright (c) 2011 George Nachman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PointerControllerDelegate

- (void)pasteFromClipboardWithEvent:(NSEvent *)event;
- (void)pasteFromSelectionWithEvent:(NSEvent *)event;
- (void)openTargetWithEvent:(NSEvent *)event;
- (void)openTargetInBackgroundWithEvent:(NSEvent *)event;
- (void)smartSelectAndMaybeCopyWithEvent:(NSEvent *)event
                        ignoringNewlines:(BOOL)ignoringNewlines;
- (void)openContextMenuWithEvent:(NSEvent *)event;
- (void)nextTabWithEvent:(NSEvent *)event;
- (void)previousTabWithEvent:(NSEvent *)event;
- (void)nextWindowWithEvent:(NSEvent *)event;
- (void)previousWindowWithEvent:(NSEvent *)event;
- (void)movePaneWithEvent:(NSEvent *)event;
- (void)sendEscapeSequence:(NSString *)text withEvent:(NSEvent *)event;
- (void)sendHexCode:(NSString *)codes withEvent:(NSEvent *)event;
- (void)sendText:(NSString *)text withEvent:(NSEvent *)event;
- (void)selectPaneLeftWithEvent:(NSEvent *)event;
- (void)selectPaneRightWithEvent:(NSEvent *)event;
- (void)selectPaneAboveWithEvent:(NSEvent *)event;
- (void)selectPaneBelowWithEvent:(NSEvent *)event;
- (void)newWindowWithProfile:(NSString *)guid withEvent:(NSEvent *)event;
- (void)newTabWithProfile:(NSString *)guid withEvent:(NSEvent *)event;
- (void)newVerticalSplitWithProfile:(NSString *)guid withEvent:(NSEvent *)event;
- (void)newHorizontalSplitWithProfile:(NSString *)guid withEvent:(NSEvent *)event;
- (void)selectNextPaneWithEvent:(NSEvent *)event;
- (void)selectPreviousPaneWithEvent:(NSEvent *)event;
- (void)extendSelectionWithEvent:(NSEvent *)event;

@end

@interface PointerController : NSObject {
    NSObject<PointerControllerDelegate> *delegate_;
    int mouseDownButton_;
    int clicks_;
}

@property (nonatomic, assign) NSObject<PointerControllerDelegate> *delegate;

- (BOOL)mouseDown:(NSEvent *)event withTouches:(int)numTouches;
- (BOOL)mouseUp:(NSEvent *)event withTouches:(int)numTouches;
// TODO: FX EDIT
//- (void)swipeWithEvent:(NSEvent *)event;
- (BOOL)eventEmulatesRightClick:(NSEvent *)event;
- (BOOL)viewShouldTrackTouches;
- (void)notifyLeftMouseDown;

@end
