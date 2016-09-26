//
//  SolidColorView.m
//  iTerm
//
//  Created by George Nachman on 12/6/11.
//

#import "SolidColorView.h"

@implementation SolidColorView
- (id)initWithFrame:(NSRect)frame color:(NSColor*)color
{
    self = [super initWithFrame:frame];
    if (self) {
        color_ = [color retain];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [color_ setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

- (void)setColor:(NSColor*)color
{
    [color_ autorelease];
    color_ = [color retain];
}

- (NSColor*)color
{
    return color_;
}

- (BOOL)isFlipped
{
    return isFlipped_;
}

- (void)setFlipped:(BOOL)value
{
    isFlipped_ = value;
}

@end
