#import <Cocoa/Cocoa.h>
#import "ConnectionStatusArguments.h"

@protocol RoyalTsxManagedConnectionControllerProtocol <NSObject>

- (void)sessionResized;
- (void)sessionStatusChanged:(ConnectionStatusArguments*)args;

@end
