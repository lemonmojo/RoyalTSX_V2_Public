#import <Cocoa/Cocoa.h>
#import "RoyalTsxManagedConnectionControllerProtocol.h"

@protocol RoyalTsxNativeConnectionControllerProtocol <NSObject>

- (NSView*)sessionView;
- (NSObject<RoyalTsxManagedConnectionControllerProtocol>*)parentController;

- (id<RoyalTsxNativeConnectionControllerProtocol>)initWithParentController:(NSObject<RoyalTsxManagedConnectionControllerProtocol>*)parent andMainWindow:(NSWindow*)window;

- (void)connectWithOptions:(NSDictionary*)options;
- (void)disconnect;
- (void)focusSession;
- (void)refreshScreen;
- (NSImage*)getScreenshot;
- (NSSize)contentSize;

@end