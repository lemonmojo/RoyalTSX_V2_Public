//
//  AlertTrigger.m
//  iTerm
//
//  Created by George Nachman on 9/23/11.
//

#import "AlertTrigger.h"
#import "PTYSession.h"
#import "PTYTab.h"
#import "PseudoTerminal.h"

@implementation AlertTrigger

- (NSString *)title
{
    return @"Show Alert…";
}

- (NSString *)paramPlaceholder
{
    return @"Enter text to show in alert";
}

- (BOOL)takesParameter
{
    return YES;
}

- (void)performActionWithValues:(NSArray *)values inSession:(PTYSession *)aSession
{
    if (disabled_) {
        return;
    }
    NSString *message = [self paramWithBackreferencesReplacedWithValues:values];

    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:@"OK"
                                   alternateButton:@"Show Session"
                                       otherButton:@"Disable This Alert"
                         informativeTextWithFormat:@""];
    switch ([alert runModal]) {
        case NSAlertDefaultReturn:
            break;
            
        case NSAlertAlternateReturn: {
            PseudoTerminal *term = [[aSession tab] realParentWindow];
            [[term window] makeKeyAndOrderFront:nil];
            [[term tabView] selectTabViewItemWithIdentifier:[aSession tab]];
            [[aSession tab] setActiveSession:aSession];
            break;
            
        case NSAlertOtherReturn:
            disabled_ = YES;
            break;
        }
            
        default:
            break;
    }
}

@end
