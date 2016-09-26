#import <Cocoa/Cocoa.h>

typedef enum _rtsConnectionStatus {
    rtsConnectionClosed = 0,
    rtsConnectionConnecting = 1,
    rtsConnectionConnected = 2,
    rtsConnectionDisconnecting = 3
} rtsConnectionStatus;

@interface ConnectionStatusArguments : NSObject {
    rtsConnectionStatus status;
    NSInteger errorNumber;
    NSString *errorMessage;
}

@property (nonatomic, readwrite) rtsConnectionStatus status;
@property (nonatomic, readwrite) NSInteger errorNumber;
@property (nonatomic, copy) NSString *errorMessage;

+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus;
+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber;
+ (ConnectionStatusArguments*)argumentsWithStatus:(rtsConnectionStatus)aStatus errorNumber:(NSInteger)aErrorNumber andErrorMessage:(NSString*)aErrorMessage;

- (id)init;
- (id)initWithStatus:(rtsConnectionStatus)aStatus;
- (id)initWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber;
- (id)initWithStatus:(rtsConnectionStatus)aStatus andErrorNumber:(NSInteger)aErrorNumber andErrorMessage:(NSString*)aErrorMessage;

@end
