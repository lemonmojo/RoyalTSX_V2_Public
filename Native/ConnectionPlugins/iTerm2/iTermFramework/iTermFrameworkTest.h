//
//  iTermFrameworkTest.h
//  iTerm
//
//  Created by Felix Deimel on 12.03.13.
//
//

#import <Foundation/Foundation.h>

#import "ProfileModel.h"
#import "WindowControllerInterface.h"

@interface iTermFrameworkTest : NSObject <WindowControllerInterface> {
    NSWindow *win;
    PTYTab *tab;
    PTYSession *session;
}

- (NSWindow*) window;

- (void) test;
-(id)addNewSession:(NSDictionary *)addressbookEntry;
- (Profile *)defaultBookmark;

- (BOOL)fitSessionToCurrentViewSize:(PTYSession*)aSession;
- (NSSize)sessionSizeForViewSize:(PTYSession *)aSession;
- (BOOL)scrollbarShouldBeVisible;
- (NSRect)maxFrame;
- (NSString *)currentSessionName;

// PseudoTerminal Implementation
- (BOOL)useTransparency;
- (BOOL)broadcastInputToSession:(PTYSession *)session;
- (BOOL)inInstantReplay;
- (NSArray*)sessions;
- (void)futureInvalidateRestorableState;

@end
