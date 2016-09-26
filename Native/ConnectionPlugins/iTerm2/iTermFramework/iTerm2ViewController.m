//
//  iTerm2ViewController.m
//  iTerm
//
//  Created by Felix Deimel on 13.03.13.
//
//

#import "iTerm2ViewController.h"
#import "PTYTab.h"
#import "PTYSession.h"
#import "WindowControllerInterface.h"
#import "SessionView.h"
#import "PTYScrollView.h"
#import "PTYTextView.h"
#import "ITAddressBookMgr.h"
#import "VT100Screen.h"
#import "iTermKeyBindingMgr.h"
#import "iTermController.h"
#import "Trigger.h"
#import "CoprocessTrigger.h"

NSObject* getViewControllerForRoyalTsxPlugin(NSObject<RoyalTsxManagedConnectionControllerProtocol> *parentController, NSWindow* mainWindow) {
    return [[iTerm2ViewController alloc] initWithParentController:parentController andMainWindow:mainWindow];
}

NSMutableArray* g_allSessions;
BOOL g_broadcastInputToAllSessions;

@implementation iTerm2ViewController

@synthesize parentController;

- (id<RoyalTsxNativeConnectionControllerProtocol>)initWithParentController:(NSObject<RoyalTsxManagedConnectionControllerProtocol>*)parent andMainWindow:(NSWindow*)window; {
    if (![super init])
		return nil;
    
    parentController = parent;
    mainWindow = window;
    
    pbHistoryView = [[PasteboardHistoryWindowController alloc] init];
    autocompleteView = [[AutocompleteView alloc] init];
    
    @try {
        [[PreferencePanel sharedInstance] readPreferences];
    }
    @catch (NSException *exception) { }
    
	return self;
}

- (void)dealloc {
    NSLog(@"iTerm2: dealloc");
    
    [autocompleteView shutdown];
    [autocompleteView release];
    autocompleteView = nil;
    
    [pbHistoryView shutdown];
    [pbHistoryView release];
    pbHistoryView = nil;
    
    currentSession = nil;
    currentTab = nil;
    parentController = nil;
    
	[super dealloc];
}

- (NSView*)sessionView {
    if (!isClosed &&
        currentSession) {
        return [currentSession view];
    }
    
    return nil;
}

- (void)toggleFind {
    if (!isClosed && currentSession) {
        [currentSession toggleFind];
    }
}

- (BOOL)isLogging
{
    if (isClosed ||
        !currentSession) {
        return NO;
    }
    
    return [currentSession logging];
}

- (void)toggleLogging
{
    if (self.isLogging) {
        [self stopLogging];
    } else {
        [self startLogging];
    }
}

- (void)startLogging
{
    if (isClosed ||
        !currentSession ||
        currentSession.logging) {
        return;
    }
    
    [currentSession logStart];
}

- (void)stopLogging
{
    if (isClosed ||
        !currentSession ||
        !currentSession.logging) {
        return;
    }
    
    [currentSession logStop];
}

- (void)connectionStatusChanged:(rtsConnectionStatus)newStatus withContent:(NSString*)content {
    if (!parentController) {
        return;
    }
    
    ConnectionStatusArguments *args = [ConnectionStatusArguments argumentsWithStatus:newStatus
                                                                         errorNumber:0
                                                                     andErrorMessage:content];
    //NSLog(@"err msg: %@", args.errorMessage);
    
    if (parentController && [parentController respondsToSelector:@selector(sessionStatusChanged:)]) {
        [parentController performSelectorOnMainThread:@selector(sessionStatusChanged:) withObject:args waitUntilDone:YES];
    }
}

- (NSSize)contentSize {
    return NSMakeSize(0, 0);
}

- (void)refreshScreen {
    
}

- (void)connectWithOptions:(NSDictionary *)options {
    isClosed = NO;
    disconnectInProgress = NO;
    
    //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ThreeFingerTapEmulatesThreeFingerClick"];
    //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"PasteFromClipboard"];
    
    NSDictionary *aDict = [self buildBookmark:options];
    
    NSString *command = [options objectForKey:@"Command"];
    NSArray *arguments = [options objectForKey:@"Arguments"];
    
    currentSession = [self addNewSession:aDict];
    [[iTerm2ViewController allSessions] addObject:currentSession];
    
    NSRect tempFrame = [[options objectForKey:@"InitialFrame"] rectValue];
    
    [self setupSession:currentSession title:@"Royal TSX" withSize:&tempFrame.size];
    
    [currentSession setPreferencesFromAddressBookEntry:aDict];
    
    currentTab = [[PTYTab alloc] initWithSession:currentSession];
    currentTab.parentWindow = (PseudoTerminal*)self;
    
    [currentSession setIgnoreResizeNotifications:NO];
    [currentTab setReportIdealSizeAsCurrent:NO];
    
    [self performSelectorOnMainThread:@selector(connectFinal:) withObject:[NSArray arrayWithObjects:command, arguments, nil] waitUntilDone:NO];
}

- (NSDictionary*)buildBookmark:(NSDictionary*)options {
    NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    
    [newDict setObject:@"No" forKey:KEY_DEFAULT_BOOKMARK];
    [newDict setObject:[options objectForKey:@"DisplayName"] forKey:KEY_NAME];
    [newDict setObject:[ProfileModel freshGuid] forKey:KEY_GUID];
    
    [newDict setObject:[NSNumber numberWithInt:-1] forKey:KEY_SCREEN];
    [newDict setObject:[NSNumber numberWithBool:NO] forKey:KEY_DISABLE_SMCUP_RMCUP];
    [newDict setObject:[options objectForKey:@"VerticalCharSpacing"] forKey:KEY_VERTICAL_SPACING];
    [newDict setObject:[options objectForKey:@"HorizontalCharSpacing"] forKey:KEY_HORIZONTAL_SPACING];
    [newDict setObject:@"No" forKey:KEY_CUSTOM_COMMAND];
    [newDict setObject:[NSNumber numberWithInt:0] forKey:KEY_WINDOW_TYPE];
    [newDict setObject:[options objectForKey:@"TerminalType"] forKey:KEY_TERMINAL_TYPE];
    [newDict setObject:[options objectForKey:@"ScrollbackLines"] forKey:KEY_SCROLLBACK_LINES];
    [newDict setObject:[options objectForKey:@"UnlimitedScrollback"] forKey:KEY_UNLIMITED_SCROLLBACK];
    [newDict setObject:[NSNumber numberWithInt:24] forKey:KEY_ROWS];
    [newDict setObject:[NSNumber numberWithInt:80] forKey:KEY_COLUMNS];
    [newDict setObject:[NSNumber numberWithInt:0] forKey:KEY_FLASHING_BELL];
    [newDict setObject:@"No" forKey:KEY_CUSTOM_DIRECTORY];
    NSString *font = [NSString stringWithFormat:@"%@ %g", [options objectForKey:@"FontName"], [[options objectForKey:@"FontSize"] floatValue]];
    [newDict setObject:font forKey:KEY_NORMAL_FONT];
    NSString *nonAsciiFont = [NSString stringWithFormat:@"%@ %g", [options objectForKey:@"NonAsciiFontName"], [[options objectForKey:@"NonAsciiFontSize"] floatValue]];
    [newDict setObject:nonAsciiFont forKey:KEY_NON_ASCII_FONT];
    [newDict setObject:[options objectForKey:@"CloseOnSessionEnd"] forKey:KEY_CLOSE_SESSIONS_ON_END];
    [newDict setObject:[options objectForKey:@"BlinkCursor"] forKey:KEY_BLINKING_CURSOR];
    NSNumber *transparency = [options objectForKey:@"Transparency"];
    [newDict setObject:transparency forKey:KEY_TRANSPARENCY];
    
    if (transparency.floatValue > 0.0) {
        isTransparent = YES;
    }
    
    [newDict setObject:[NSNumber numberWithFloat:0.0] forKey:KEY_BLEND];
    [newDict setObject:[NSNumber numberWithFloat:0.0] forKey:KEY_BLUR_RADIUS];
    [newDict setObject:[NSNumber numberWithBool:NO] forKey:KEY_BLUR];
    [newDict setObject:[NSNumber numberWithInt:0] forKey:KEY_VISUAL_BELL];
    [newDict setObject:[NSNumber numberWithInt:0] forKey:KEY_AMBIGUOUS_DOUBLE_WIDTH];
    [newDict setObject:[options objectForKey:@"Encoding"] forKey:KEY_CHARACTER_ENCODING];
    [newDict setObject:[options objectForKey:@"FontAntiAlias"] forKey:KEY_ANTI_ALIASING];
    [newDict setObject:[options objectForKey:@"NonAsciiFontAntiAlias"] forKey:KEY_NONASCII_ANTI_ALIASED];
    
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi0Color"]] forKey:KEY_ANSI_0_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi1Color"]] forKey:KEY_ANSI_1_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi2Color"]] forKey:KEY_ANSI_2_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi3Color"]] forKey:KEY_ANSI_3_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi4Color"]] forKey:KEY_ANSI_4_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi5Color"]] forKey:KEY_ANSI_5_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi6Color"]] forKey:KEY_ANSI_6_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi7Color"]] forKey:KEY_ANSI_7_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi8Color"]] forKey:KEY_ANSI_8_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi9Color"]] forKey:KEY_ANSI_9_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi10Color"]] forKey:KEY_ANSI_10_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi11Color"]] forKey:KEY_ANSI_11_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi12Color"]] forKey:KEY_ANSI_12_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi13Color"]] forKey:KEY_ANSI_13_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi14Color"]] forKey:KEY_ANSI_14_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"Ansi15Color"]] forKey:KEY_ANSI_15_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"ForegroundColor"]] forKey:KEY_FOREGROUND_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"BackgroundColor"]] forKey:KEY_BACKGROUND_COLOR];
    //[newDict setObject:[ITAddressBookMgr encodeColor:[boldColor color]] forKey:KEY_BOLD_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"SelectionColor"]] forKey:KEY_SELECTION_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"SelectedTextColor"]] forKey:KEY_SELECTED_TEXT_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"CursorColor"]] forKey:KEY_CURSOR_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"CursorTextColor"]] forKey:KEY_CURSOR_TEXT_COLOR];
    [newDict setObject:[options objectForKey:@"SmartCursorColor"] forKey:KEY_SMART_CURSOR_COLOR];
    [newDict setObject:[ITAddressBookMgr encodeColor:[options objectForKey:@"BoldColor"]] forKey:KEY_BOLD_COLOR];
    [newDict setObject:[NSNumber numberWithInt:0] forKey:KEY_BOOKMARK_GROWL_NOTIFICATIONS];
    [newDict setObject:[options objectForKey:@"SetLocaleVariables"] forKey:KEY_SET_LOCALE_VARS];
    [newDict setObject:[options objectForKey:@"SilenceBell"] forKey:KEY_SILENCE_BELL];
    
    [newDict setObject:[NSNumber numberWithInt:0] forKey:KEY_IDLE_CODE];
    [newDict setObject:[options objectForKey:@"KeepAlive"] forKey:KEY_SEND_CODE_WHEN_IDLE];
    
    if ([options objectForKey:@"EnableLogging"] && ![[options objectForKey:@"LogDirectory"] isEqualToString:@""]) {
        [newDict setObject:[options objectForKey:@"EnableLogging"] forKey:KEY_AUTOLOG];
        [newDict setObject:[options objectForKey:@"LogDirectory"] forKey:KEY_LOGDIR];
    }
    
    ITermCursorType cursorType = CURSOR_BOX;
    
    if ([[options objectForKey:@"CursorAppearance"] intValue] == 1) {
        cursorType = CURSOR_UNDERLINE;
    } else if ([[options objectForKey:@"CursorAppearance"] intValue] == 2) {
        cursorType = CURSOR_VERTICAL;
    }
    
    [newDict setObject:[NSNumber numberWithInt:cursorType] forKey:KEY_CURSOR_TYPE];
    //[newDict setObject:[NSNumber numberWithFloat:[minimumContrast floatValue]] forKey:KEY_MINIMUM_CONTRAST];
    
    if ([[options objectForKey:@"NumPadMode"] intValue] == 0) {
        [iTermKeyBindingMgr setKeyMappingsToPreset:@"xterm with Numeric Keypad" inBookmark:newDict];
    } else {
        [iTermKeyBindingMgr setKeyMappingsToPreset:@"xterm Defaults" inBookmark:newDict];
    }
    
    //[iTermKeyBindingMgr setKeyMappingsToPreset:@"Terminal.app Compatiblity" inBookmark:newDict];
    //NSLog(@"YO:\n%@", newDict.description);
    
    // Enable ^⇧←, ⌥←, ⌥→
    [iTermKeyBindingMgr setMappingAtIndex:0
                                   forKey:@"0xf702-0x260000"
                                   action:KEY_ACTION_HEX_CODE
                                    value:@"0x1b 0x1b 0x5b 0x44"
                                createNew:YES
                               inBookmark:newDict];
    
    [iTermKeyBindingMgr setMappingAtIndex:0
                                   forKey:@"0xf702-0x280000"
                                   action:KEY_ACTION_HEX_CODE
                                    value:@"0x1b 0x1b 0x5b 0x44"
                                createNew:YES
                               inBookmark:newDict];
    
    [iTermKeyBindingMgr setMappingAtIndex:0
                                   forKey:@"0xf703-0x280000"
                                   action:KEY_ACTION_HEX_CODE
                                    value:@"0x1b 0x1b 0x5b 0x43"
                                createNew:YES
                               inBookmark:newDict];
    
    // Enable ^←, ^→
    [iTermKeyBindingMgr setMappingAtIndex:0
                                   forKey:@"0xf702-0x240000"
                                   action:KEY_ACTION_ESCAPE_SEQUENCE
                                    value:@"[1;5D"
                                createNew:YES
                               inBookmark:newDict];
    
    [iTermKeyBindingMgr setMappingAtIndex:0
                                   forKey:@"0xf703-0x240000"
                                   action:KEY_ACTION_ESCAPE_SEQUENCE
                                    value:@"[1;5C"
                                createNew:YES
                               inBookmark:newDict];
    
    [newDict setObject:[options objectForKey:@"EnableXtermMouseReporting"] forKey:KEY_XTERM_MOUSE_REPORTING];
    
    [newDict setObject:[options objectForKey:@"LeftOptionKeyMode"] forKey:KEY_OPTION_KEY_SENDS];
    [newDict setObject:[options objectForKey:@"RightOptionKeyMode"] forKey:KEY_RIGHT_OPTION_KEY_SENDS];
    
    NSString* kDeleteKeyString = @"0x7f-0x0";
    
    BOOL sendCtrlH = [[options objectForKey:@"DeleteKeySendsCtrlH"] boolValue];
    
    if (sendCtrlH) {
        [iTermKeyBindingMgr setMappingAtIndex:0
                                       forKey:kDeleteKeyString
                                       action:KEY_ACTION_SEND_C_H_BACKSPACE
                                        value:@""
                                    createNew:YES
                                   inBookmark:newDict];
    } else {
        [iTermKeyBindingMgr removeMappingWithCode:0x7f
                                        modifiers:0
                                       inBookmark:newDict];
    }
    
    /* NSDictionary *triggerZmodemSend = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"\\*\\*B0100", kTriggerRegexKey,
                                       NSStringFromClass([MuteCoprocessTrigger class]), kTriggerActionKey,
                                       @"~/Downloads/iterm2-send-zmodem.sh", kTriggerParameterKey,
                                       nil];
    
    NSDictionary *triggerZmodemRecv = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"\\*\\*B00000000000000", kTriggerRegexKey,
                                       NSStringFromClass([MuteCoprocessTrigger class]), kTriggerActionKey,
                                       @"~/Downloads/iterm2-recv-zmodem.sh", kTriggerParameterKey,
                                       nil];
    
    NSArray* triggers = [NSArray arrayWithObjects:
                         [triggerZmodemSend copy],
                         [triggerZmodemRecv copy],
                         nil];
    
    [newDict setObject:triggers forKey:KEY_TRIGGERS]; */
    
    /*
     STILL MISSING:
     
     2013-03-25 16:56:18.501 iTerm2Tester[6483:303] key: Background Image Location, value:
     2013-03-25 16:56:18.502 iTerm2Tester[6483:303] key: Shortcut, value:
     2013-03-25 16:56:18.503 iTerm2Tester[6483:303] key: Use Bright Bold, value: 1
     2013-03-25 16:56:18.511 iTerm2Tester[6483:303] key: Working Directory, value: /Users/fx
     2013-03-25 16:56:18.512 iTerm2Tester[6483:303] key: Disable Window Resizing, value: 1
     2013-03-25 16:56:18.513 iTerm2Tester[6483:303] key: Sync Title, value: 0
     2013-03-25 16:56:18.513 iTerm2Tester[6483:303] key: Command, value:
     2013-03-25 16:56:18.515 iTerm2Tester[6483:303] key: Use Bold Font, value: 1
     2013-03-25 16:56:18.518 iTerm2Tester[6483:303] key: Silence Bell, value: 0
     
     Keyboard Map
     */
    
    return newDict;
}

- (void)connectFinal:(NSArray*)args {
    NSString *command = [args objectAtIndex:0];
    NSArray *arguments = [args objectAtIndex:1];
    //NSDictionary *environment = [NSDictionary dictionary];
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    
    [currentSession startProgram:command arguments:arguments environment:environment isUTF8:YES asLoginSession:YES];
    [[iTermController sharedInstance] setCurrentTerminal:currentTab.realParentWindow];
    
    [self connectionStatusChanged:rtsConnectionConnected withContent:@""];
    
    /* [currentSession updateDisplay];
    [[currentSession view] setBackgroundDimmed:NO];
    [currentSession setFocused:YES];
    [[currentSession TEXTVIEW] refresh];
    [[currentSession TEXTVIEW] setNeedsDisplay:YES]; */
}

- (void)focusSession {
    if (!isClosed &&
        currentSession) {
        [currentSession takeFocus];
        [[iTermController sharedInstance] setCurrentTerminal:currentTab.realParentWindow];
    }
}

- (void)sendText:(NSString*)text {
    /* if (((ITTerminalView*)sessionView) != nil && ((ITTerminalView*)sessionView).currentSession != nil) {
        [((ITTerminalView*)sessionView).currentSession insertText:text];
    } */
}

- (void)runCommand:(NSString*)command {
    /* if (currentSession) {
        [currentSession sendCommand:command];
    } */
}

- (void)disconnect {
    NSLog(@"iTerm2: Trying to disconnect");
    
    if (!isClosed &&
        !disconnectInProgress &&
        currentSession) {
        disconnectInProgress = YES;
        [currentSession terminate];
    }
}

/* - (void)sessionClosed:(PTYSession*)session withContent:(NSString*)content {
    [self connectionStatusChanged:mrConnectionClosed withContent:content];
} */

- (NSImage*)getScreenshot {
    if (isClosed ||
        !currentSession ||
        !self.sessionView) {
        return nil;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSBitmapImageRep *imageRep = [self.sessionView bitmapImageRepForCachingDisplayInRect:[self.sessionView frame]];
    [self.sessionView cacheDisplayInRect:[self.sessionView frame] toBitmapImageRep:imageRep];
    
    NSImage *image = [[NSImage alloc] initWithSize:self.sessionView.frame.size];
    [image addRepresentation:imageRep];
    
    [pool drain];
    pool = nil;
    
    return [image autorelease];
}

- (void)clearBuffer {
    if (currentSession) {
        [currentSession clearBuffer];
    }
}

- (void)clearScrollbackBuffer {
    if (currentSession) {
        [currentSession clearScrollbackBuffer];
    }
}

- (void)biggerFont {
    if (currentSession) {
        [currentSession changeFontSizeDirection:1];
    }
}

- (void)smallerFont {
    if (currentSession) {
        [currentSession changeFontSizeDirection:-1];
    }
}

- (void)pasteSpecial:(id)sender {
    if (currentSession) {
        [currentSession paste:sender];
    }
}

- (void)pasteHistory {
    if (currentSession) {
        [pbHistoryView popInSession:[self currentSession]];
    }
}

- (void)autocomplete {
    if (currentSession) {
        if ([[autocompleteView window] isVisible]) {
            [autocompleteView more];
        } else {
            [autocompleteView popInSession:[self currentSession]];
        }
    }
}

- (void)setMark {
    if (currentSession) {
        [currentSession saveScrollPosition];
    }
}

- (void)jumpToMark {
    if (currentSession) {
        [currentSession jumpToSavedScrollPosition];
    }
}









-(id)addNewSession:(NSDictionary *)addressbookEntry
{
    assert(addressbookEntry);
    
    // Initialize a new session
    currentSession = [[PTYSession alloc] init];
    
    [[currentSession SCREEN] setUnlimitedScrollback:[[addressbookEntry objectForKey:KEY_UNLIMITED_SCROLLBACK] boolValue]];
    [[currentSession SCREEN] setScrollback:[[addressbookEntry objectForKey:KEY_SCROLLBACK_LINES] intValue]];
    
    // set our preferences
    [currentSession setAddressBookEntry:addressbookEntry];
    // Add this session to our term and make it current
    
    if ([currentSession SCREEN]) {
        /* NSString *command = @"ssh";
         NSArray *arguments = [NSArray arrayWithObjects:@"root@192.168.0.211", nil]; */
        
        /* NSString *command = @"login";
        NSArray *arguments = [NSArray arrayWithObjects:@"-fp", NSUserName(), nil];
        
        [self performSelectorOnMainThread:@selector(connectFinal:) withObject:[NSArray arrayWithObjects:command, arguments, nil] waitUntilDone:YES]; */
    }
    
    //[session release];
    return currentSession;
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

- (void)setupSession:(PTYSession *)aSession
               title:(NSString *)title
            withSize:(NSSize*)size
{
    NSDictionary *tempPrefs;
    
    NSParameterAssert(aSession != nil);
    
    // set some default parameters
    if ([aSession addressBookEntry] == nil) {
        tempPrefs = [[ProfileModel sharedInstance] defaultBookmark];
        if (tempPrefs != nil) {
            // Use the default bookmark. This path is taken with applescript's
            // "make new session at the end of sessions" command.
            [aSession setAddressBookEntry:tempPrefs];
        } else {
            // get the hardcoded defaults
            NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
            [ITAddressBookMgr setDefaultsInBookmark:dict];
            [dict setObject:[ProfileModel freshGuid] forKey:KEY_GUID];
            [aSession setAddressBookEntry:dict];
            tempPrefs = dict;
        }
    } else {
        tempPrefs = [aSession addressBookEntry];
    }
    
    int desiredRows_ = -1;
    int desiredColumns_ = -1;
    int nextSessionRows_ = -1;
    int nextSessionColumns_ = -1;
    
    int rows = [[tempPrefs objectForKey:KEY_ROWS] intValue];
    int columns = [[tempPrefs objectForKey:KEY_COLUMNS] intValue];
    if (desiredRows_ < 0) {
        desiredRows_ = rows;
        desiredColumns_ = columns;
    }
    if (nextSessionRows_) {
        rows = nextSessionRows_;
        nextSessionRows_ = 0;
    }
    if (nextSessionColumns_) {
        columns = nextSessionColumns_;
        nextSessionColumns_ = 0;
    }
    // rows, columns are set to the bookmark defaults. Make sure they'll fit.
    
    NSSize charSize = [PTYTextView charSizeForFont:[ITAddressBookMgr fontWithDesc:[tempPrefs objectForKey:KEY_NORMAL_FONT]]
                                 horizontalSpacing:[[tempPrefs objectForKey:KEY_HORIZONTAL_SPACING] floatValue]
                                   verticalSpacing:[[tempPrefs objectForKey:KEY_VERTICAL_SPACING] floatValue]];
    
    int windowType_ = WINDOW_TYPE_NORMAL;
    
    if (windowType_ == WINDOW_TYPE_TOP ||
        windowType_ == WINDOW_TYPE_BOTTOM ||
        windowType_ == WINDOW_TYPE_LEFT) {
        NSRect windowFrame = [[self window] frame];
        BOOL hasScrollbar = [self scrollbarShouldBeVisible];
        NSSize contentSize = [PTYScrollView contentSizeForFrameSize:windowFrame.size
                                              hasHorizontalScroller:NO
                                                hasVerticalScroller:hasScrollbar
                                                         borderType:NSNoBorder];
        if (windowType_ != WINDOW_TYPE_LEFT) {
            columns = (contentSize.width - MARGIN*2) / charSize.width;
        }
    }
    if (size == nil && YES) {
        NSSize contentSize = [[currentSession SCROLLVIEW] documentVisibleRect].size;
        rows = (contentSize.height - VMARGIN*2) / charSize.height;
        columns = (contentSize.width - MARGIN*2) / charSize.width;
    }
    NSRect sessionRect;
    if (size != nil) {
        BOOL hasScrollbar = [self scrollbarShouldBeVisible];
        NSSize contentSize = [PTYScrollView contentSizeForFrameSize:*size
                                              hasHorizontalScroller:NO
                                                hasVerticalScroller:hasScrollbar
                                                         borderType:NSNoBorder];
        rows = (contentSize.height - VMARGIN*2) / charSize.height;
        columns = (contentSize.width - MARGIN*2) / charSize.width;
        sessionRect.origin = NSZeroPoint;
        sessionRect.size = *size;
    } else {
        sessionRect = NSMakeRect(0, 0, columns * charSize.width + MARGIN * 2, rows * charSize.height + VMARGIN * 2);
    }
    
    if ([aSession setScreenSize:sessionRect parent:self]) {
        //[self safelySetSessionSize:aSession rows:rows columns:columns];
        [aSession setPreferencesFromAddressBookEntry:tempPrefs];
        [aSession setBookmarkName:[tempPrefs objectForKey:KEY_NAME]];
        [[aSession SCREEN] setDisplay:[aSession TEXTVIEW]];
        [[aSession TERMINAL] setTrace:YES];    // debug vt100 escape sequence decode
        
        if (title) {
            [aSession setName:title];
            [aSession setDefaultName:title];
            [self setWindowTitle];
        }
    }
}









- (void)sessionWasRemoved {
    NSLog(@"iTerm2: sessionWasRemoved");
    isClosed = YES;
    
    if (currentSession) {
        NSMutableArray *allSes = [iTerm2ViewController allSessions];
        
        if ([allSes containsObject:currentSession]) {
            [allSes removeObject:currentSession];
        }
        
        [currentSession cancelTimers];
        [currentSession setTab:nil];
        [currentSession release];
        currentSession = nil;
    }
    
    if (currentTab) {
        if ([[iTermController sharedInstance] currentTerminal] == currentTab.realParentWindow) {
            [[iTermController sharedInstance] setCurrentTerminal:nil];
        }
        
        [currentTab release];
        currentTab = nil;
    }
    
    [self connectionStatusChanged:rtsConnectionClosed withContent:@""];
}

- (int)number {
    return 0;
}

- (NSWindow*)window {
    return nil;
}

- (void)windowDidResize:(NSNotification*)notification {
    if (isClosed ||
        !currentSession ||
        !self.sessionView) {
        return;
    }
    
    [SessionView windowDidResize];
    
    // Post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"iTermWindowDidResize"
                                                        object:self
                                                      userInfo:nil];
    
    [self fitSessionToCurrentViewSize:currentSession];
    
    [self futureInvalidateRestorableState];
}

- (BOOL)fitSessionToCurrentViewSize:(PTYSession*)aSession
{
    if (!aSession) {
        return NO;
    }
    
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
        NSLog(@"iTerm2: WARNING: Session has %d width", width);
        width = 1;
    }
    if (height <= 0) {
        NSLog(@"iTerm2: WARNING: Session has %d height", height);
        height = 1;
    }
    
    return NSMakeSize(width, height);
}


- (BOOL)scrollbarShouldBeVisible
{
    return YES;
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
    if (!currentSession) {
        return @"";
    }
    
    PTYSession* aSession = currentSession;
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
    NSLog(@"iTerm2: closeSession:");
    [self disconnect];
    //[self connectionStatusChanged:mrConnectionClosed withContent:@""];
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
    return currentSession;
}
- (void)setWindowTitle {
    //win.title = [self currentSessionName];
}
- (void)resetTempTitle {
    
}
- (PTYTab*)currentTab {
    return currentTab;
}
- (void)closeTab:(PTYTab*)theTab {
    NSLog(@"iTerm2: closeTab");
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
    return NSZeroRect;
}
- (NSScreen*)windowScreen {
    return [NSScreen mainScreen];
}



// PseudoTerminal Implementation

- (void)resize
{
    if (isClosed ||
        !currentSession) {
        return;
    }
    
    NSSize size = [self sessionSizeForViewSize:currentSession];
    [currentSession setWidth:size.width height:size.height];
}

- (BOOL)useTransparency {
    return isTransparent;
}

- (void)toggleBroadcastInputToAllSessions {
    g_broadcastInputToAllSessions = !g_broadcastInputToAllSessions;
    
    for (PTYSession *aSession in [iTerm2ViewController allSessions]) {
        [[aSession view] setNeedsDisplay:YES];
    }
}

- (BOOL)broadcastInputToSession:(PTYSession *)session {
    return g_broadcastInputToAllSessions;
}

- (NSArray *)broadcastSessions
{
    NSMutableArray *sesArr = [NSMutableArray array];
    
    if (g_broadcastInputToAllSessions) {
        for (PTYSession* aSession in [iTerm2ViewController allSessions]) {
            if (aSession &&
                ![aSession exited]) {
                [sesArr addObject:aSession];
            }
        }
    }
    
    return sesArr;
}

- (void)sendInputToAllSessions:(NSData *)data
{
    for (PTYSession *aSession in [self broadcastSessions]) {
        if ([aSession isTmuxClient]) {
            [aSession writeTaskNoBroadcast:data];
        } else if (![aSession isTmuxGateway]) {
            [[aSession SHELL] writeTask:data];
        }
    }
}

- (BOOL)inInstantReplay {
    return NO;
}

- (NSArray*)sessions {
    return [NSArray arrayWithObject:currentSession];
}

+ (NSMutableArray*)allSessions {
    if (!g_allSessions) {
        g_allSessions = [[NSMutableArray alloc] init];
    }
    
    return g_allSessions;
}

- (void)futureInvalidateRestorableState {
    //[[self window] futureInvalidateRestorableState];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
    if (!isClosed &&
        currentTab) {
        [currentTab notifyWindowChanged];
    }
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
    if (!isClosed &&
        currentTab) {
        [currentTab notifyWindowChanged];
    }
}

@end