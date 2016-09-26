//
//  GrowlTrigger.m
//  iTerm
//
//  Created by George Nachman on 9/23/11.
//

#import "GrowlTrigger.h"
#import "iTermGrowlDelegate.h"
#import "PTYSession.h"
#import "PTYTab.h"

@implementation GrowlTrigger

- (NSString *)title
{
    return @"Send Growl Alert…";
}

- (BOOL)takesParameter
{
    return YES;
}

- (NSString *)paramPlaceholder
{
    return @"Enter message to growl";
}

- (void)performActionWithValues:(NSArray *)values inSession:(PTYSession *)aSession
{
    iTermGrowlDelegate *gd = [iTermGrowlDelegate sharedInstance];
    [gd growlNotify:[self paramWithBackreferencesReplacedWithValues:values]
        withDescription:[NSString stringWithFormat:@"A trigger fired in session \"%@\" in tab #%d.",
                         [aSession name],
                         [[aSession tab] realObjectCount]]
        andNotification:@"Customized Message"
             andSession:aSession];
}

@end
