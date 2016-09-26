#import "ConnectionStatusArguments.h"

@implementation ConnectionStatusArguments

@synthesize status, errorNumber, errorMessage;

+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus
{
    return [[[ConnectionStatusArguments alloc] initWithStatus:aStatus] autorelease];
}

+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber
{
    return [[[ConnectionStatusArguments alloc] initWithStatus:aStatus
                                               andErrorNumber:aErrorNumber] autorelease];
}

+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus errorNumber:(NSInteger)aErrorNumber andErrorMessage:(NSString*)aErrorMessage
{
    return [[[ConnectionStatusArguments alloc] initWithStatus:aStatus
                                               andErrorNumber:aErrorNumber
                                              andErrorMessage:aErrorMessage] autorelease];
}

- (id)init
{
    self = [super init];
    
    if (self) {
        self.status = rtsConnectionClosed;
        self.errorNumber = 0;
        self.errorMessage = @"";
    }
    
    return self;
}

- (id)initWithStatus:(rtsConnectionStatus)aStatus
{
    self = [super init];
    
    if (self) {
		self.status = aStatus;
        self.errorNumber = 0;
        self.errorMessage = @"";
    }
    
    return self;
}

- (id)initWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber
{
    self = [super init];
    
    if (self) {
		self.status = aStatus;
        self.errorNumber = aErrorNumber;
        self.errorMessage = @"";
    }
    
    return self;
}

- (id)initWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber andErrorMessage:(NSString*)aErrorMessage
{
    self = [super init];
    
    if (self) {
		self.status = aStatus;
        self.errorNumber = aErrorNumber;
        self.errorMessage = aErrorMessage;
    }
    
    return self;
}

- (void)dealloc
{
    self.status = rtsConnectionClosed;
    self.errorNumber = 0;
    self.errorMessage = nil;
    
    [super dealloc];
}

@end
