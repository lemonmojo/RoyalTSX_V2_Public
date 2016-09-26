//
//  iTermFrameworkTest.m
//  iTerm
//
//  Created by Felix Deimel on 12.03.13.
//
//

#import "iTermFrameworkTest.h"
#import "PTYTab.h"
#import "PTYSession.h"
#import "WindowControllerInterface.h"
#import "SessionView.h"
#import "FakeWindow.h"
#import "PreferencePanel.h"
#import "iTermGrowlDelegate.h"
#import "PTYScrollView.h"
#import "PSMTabBarControl.h"
#import "PSMTabStyle.h"
#import "ITAddressBookMgr.h"
#import "iTermApplicationDelegate.h"
#import "iTermController.h"
#import "TmuxLayoutParser.h"
#import "IntervalMap.h"
#import "TmuxDashboardController.h"

@implementation iTermFrameworkTest

- (void) test
{
    NSRect frame = NSMakeRect(300, 400, 800, 500);
    
    win  = [[[NSWindow alloc] initWithContentRect:frame
                                        styleMask:NSResizableWindowMask | NSTitledWindowMask | NSClosableWindowMask
                                          backing:NSBackingStoreBuffered
                                            defer:NO] retain];
    
    [win makeKeyAndOrderFront:NSApp];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:win];
    
    NSDictionary *aDict = [self defaultBookmark];
    session = [self addNewSession:aDict];
    
    tab = [[PTYTab alloc] initWithSession:session];
    tab.parentWindow = self;
    
    [session setIgnoreResizeNotifications:NO];
    [tab setReportIdealSizeAsCurrent:NO];
    //[aTab release];
    
    [session setScreenSize:frame parent:self];
    session.view.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin | NSViewHeightSizable;
    
    [session setPreferencesFromAddressBookEntry:aDict];
    
    [session updateDisplay];
    [[session view] setBackgroundDimmed:NO];
    [session setFocused:YES];
    [[[self currentSession] TEXTVIEW] refresh];
    [[[self currentSession] TEXTVIEW] setNeedsDisplay:YES];
    
    [win setContentView:session.view];
    [[self window] makeFirstResponder:[session TEXTVIEW]];
}

-(id)addNewSession:(NSDictionary *)addressbookEntry
{
    assert(addressbookEntry);
    
    // Initialize a new session
    session = [[PTYSession alloc] init];
    [[session SCREEN] setUnlimitedScrollback:[[addressbookEntry objectForKey:KEY_UNLIMITED_SCROLLBACK] boolValue]];
    [[session SCREEN] setScrollback:[[addressbookEntry objectForKey:KEY_SCROLLBACK_LINES] intValue]];
    
    // set our preferences
    [session setAddressBookEntry:addressbookEntry];
    // Add this session to our term and make it current
    
    if ([session SCREEN]) {
        /* NSString *command = @"ssh";
        NSArray *arguments = [NSArray arrayWithObjects:@"root@192.168.0.211", nil]; */
        
        NSString *command = @"login";
        NSArray *arguments = [NSArray arrayWithObjects:@"-fp", NSUserName(), nil];
        
        [self performSelectorOnMainThread:@selector(connectFinal:) withObject:[NSArray arrayWithObjects:command, arguments, nil] waitUntilDone:YES];
    }
    
    //[session release];
    return session;
}

- (void)connectFinal:(NSArray*)args {
    [session startProgram:[args objectAtIndex:0] arguments:[args objectAtIndex:1] environment:[NSDictionary dictionary] isUTF8:YES asLoginSession:YES];
    
    //[self connectionStatusChanged:mrConnectionConnected withContent:@""];
}

- (Profile *)defaultBookmark
{
    Profile *aDict = [[ProfileModel sharedInstance] defaultBookmark];
    if (!aDict) {
        NSMutableDictionary* temp = [[[NSMutableDictionary alloc] init] autorelease];
        [ITAddressBookMgr setDefaultsInBookmark:temp];
        [temp setObject:[ProfileModel freshGuid] forKey:KEY_GUID];
        aDict = temp;
    }
    return aDict;
}

- (NSWindow *)window {
    return win;
}

- (void)windowDidResize:(NSNotification*)notification {
    [SessionView windowDidResize];
    
    // Post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"iTermWindowDidResize"
                                                        object:self
                                                      userInfo:nil];
    
    [self fitSessionToCurrentViewSize:session];
    
    [self futureInvalidateRestorableState];
}

- (BOOL)fitSessionToCurrentViewSize:(PTYSession*)aSession
{
    if ([aSession isTmuxClient]) {
        return NO;
    }
    NSSize temp = [self sessionSizeForViewSize:aSession];
    int width = temp.width;
    int height = temp.height;
    if ([aSession rows] == height &&
        [aSession columns] == width) {
        return NO;
    }
    if (width == [aSession columns] && height == [aSession rows]) {
        return NO;
    }
    
    [aSession setWidth:width height:height];
    [[aSession SCROLLVIEW] setLineScroll:[[aSession TEXTVIEW] lineHeight]];
    [[aSession SCROLLVIEW] setPageScroll:2*[[aSession TEXTVIEW] lineHeight]];
    if ([aSession backgroundImagePath]) {
        [aSession setBackgroundImagePath:[aSession backgroundImagePath]];
    }
    return YES;
}

- (NSSize)sessionSizeForViewSize:(PTYSession *)aSession
{
    BOOL hasScrollbar = YES;
    [[aSession SCROLLVIEW] setHasVerticalScroller:hasScrollbar];
    NSSize size = [[aSession view] maximumPossibleScrollViewContentSize];
    int width = (size.width - MARGIN*2) / [[aSession TEXTVIEW] charWidth];
    int height = (size.height - VMARGIN*2) / [[aSession TEXTVIEW] lineHeight];
    if (width <= 0) {
        NSLog(@"WARNING: Session has %d width", width);
        width = 1;
    }
    if (height <= 0) {
        NSLog(@"WARNING: Session has %d height", height);
        height = 1;
    }
    
    return NSMakeSize(width, height);
}


- (BOOL)scrollbarShouldBeVisible
{
    return (![self anyFullScreen] &&
            ![[PreferencePanel sharedInstance] hideScrollbar]);
}

- (NSRect)maxFrame
{
    NSRect visibleFrame = NSZeroRect;
    for (NSScreen* screen in [NSScreen screens]) {
        visibleFrame = NSUnionRect(visibleFrame, [screen visibleFrame]);
    }
    return visibleFrame;
}

- (NSString *)currentSessionName
{
    PTYSession* aSession = [self currentSession];
    return [aSession windowTitle] ? [aSession windowTitle] : [aSession defaultName];
}



// WindowControllerInterface Implementation

- (void)sessionInitiatedResize:(PTYSession*)session width:(int)width height:(int)height {
    
}
- (BOOL)fullScreen {
    return NO;
}
- (BOOL)anyFullScreen {
    return NO;
}
- (void)closeSession:(PTYSession*)aSession {
    NSLog(@"closeSession:");
}
- (IBAction)nextTab:(id)sender {
    
}
- (IBAction)previousTab:(id)sender {
    
}
- (void)setLabelColor:(NSColor *)color forTabViewItem:tabViewItem {
    
}
- (void)setTabColor:(NSColor *)color forTabViewItem:tabViewItem {
    
}
- (NSColor*)tabColorForTabViewItem:(NSTabViewItem*)tabViewItem {
    return nil;
}
- (void)enableBlur:(double)radius {
    
}
- (void)disableBlur {
    
}
- (BOOL)tempTitle {
    return NO;
}
- (void)fitWindowToTab:(PTYTab*)tab {
    
}
- (PTYTabView *)tabView {
    return nil;
}
- (PTYSession *)currentSession {
    return session;
}
- (void)setWindowTitle {
    win.title = [self currentSessionName];
}
- (void)resetTempTitle {
    
}
- (PTYTab*)currentTab {
    return tab;
}
- (void)closeTab:(PTYTab*)theTab {
    
}

- (void)windowSetFrameTopLeftPoint:(NSPoint)point {
    
}
- (void)windowPerformMiniaturize:(id)sender {
    
}
- (void)windowDeminiaturize:(id)sender {
    
}
- (void)windowOrderFront:(id)sender {
    
}
- (void)windowOrderBack:(id)sender {
    
}
- (BOOL)windowIsMiniaturized {
    return NO;
}
- (NSRect)windowFrame {
    return win.frame;
}
- (NSScreen*)windowScreen {
    return win.screen;
}



// PseudoTerminal Implementation

- (BOOL)useTransparency {
    return NO;
}

- (BOOL)broadcastInputToSession:(PTYSession *)session {
    return NO;
}

- (BOOL)inInstantReplay {
    return NO;
}

- (NSArray*)sessions {
    return [NSArray arrayWithObject:session];
}

- (void)futureInvalidateRestorableState {
    [[self window] futureInvalidateRestorableState];
}

@end
