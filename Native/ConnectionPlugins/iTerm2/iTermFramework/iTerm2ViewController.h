//
//  iTerm2ViewController.h
//  iTerm
//
//  Created by Felix Deimel on 13.03.13.
//
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ConnectionStatusArguments.h"
#import "ProfileModel.h"
#import "PasteboardHistory.h"
#import "Autocomplete.h"
#import "RoyalTsxManagedConnectionControllerProtocol.h"
#import "RoyalTsxNativeConnectionControllerProtocol.h"
#import "PTYTask.h"

@class PTYSession;
@class PTYTab;

NSObject* getViewControllerForRoyalTsxPlugin(NSObject<RoyalTsxManagedConnectionControllerProtocol> *parentController, NSWindow* mainWindow);

@interface iTerm2ViewController : NSObject<RoyalTsxNativeConnectionControllerProtocol, WindowControllerInterface> {
    NSWindow *mainWindow;
    NSObject<RoyalTsxManagedConnectionControllerProtocol> *parentController;
    
    PTYSession *currentSession;
    PTYTab *currentTab;
    
    BOOL isClosed;
    BOOL disconnectInProgress;
    BOOL isTransparent;
    
    PasteboardHistoryWindowController* pbHistoryView;
    AutocompleteView* autocompleteView;
}

@property (nonatomic, assign) NSObject *parentController;

- (NSView*)sessionView;
- (void)toggleFind;

- (BOOL)isLogging;
- (void)toggleLogging;
- (void)startLogging;
- (void)stopLogging;

- (void)toggleBroadcastInputToAllSessions;

- (void)connectionStatusChanged:(rtsConnectionStatus)newStatus withContent:(NSString*)content;
//- (void)connectWithCommand:(NSString*)command andArguments:(NSArray*)arguments andOptions:(iTerm2Options*)options;
- (void)connectFinal:(NSArray*)args;
- (void)disconnect;
- (void)focusSession;
- (void)sendText:(NSString*)text;
- (void)runCommand:(NSString*)command;
- (NSImage*)getScreenshot;
- (void)clearBuffer;
- (void)clearScrollbackBuffer;
- (void)biggerFont;
- (void)smallerFont;
- (void)pasteSpecial:(id)sender;
- (void)pasteHistory;
- (void)autocomplete;
- (void)setMark;
- (void)jumpToMark;


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