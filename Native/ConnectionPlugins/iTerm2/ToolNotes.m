//
//  ToolNotes.m
//  iTerm
//
//  Created by George Nachman on 9/19/11.
//  Copyright 2011 Georgetech. All rights reserved.
//

#import "ToolNotes.h"
#import "NSFileManager+DirectoryLocations.h"

static NSString *kToolNotesSetTextNotification = @"kToolNotesSetTextNotification";

@interface ToolNotes ()
- (NSString *)filename;
@end

@implementation ToolNotes

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        filemanager_ = [[NSFileManager alloc] init];

        NSScrollView *scrollview = [[[NSScrollView alloc]
                                     initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)] autorelease];
        [scrollview setHasVerticalScroller:YES];
        [scrollview setHasHorizontalScroller:NO];
        [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        NSSize contentSize = [scrollview contentSize];
        textView_ = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
        [textView_ setAllowsUndo:YES];
        [textView_ setMinSize:NSMakeSize(0.0, contentSize.height)];
        [textView_ setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [textView_ setVerticallyResizable:YES];
        [textView_ setHorizontallyResizable:NO];
        [textView_ setAutoresizingMask:NSViewWidthSizable];

        [[textView_ textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[textView_ textContainer] setWidthTracksTextView:YES];
        [textView_ setDelegate:self];
        [textView_ readRTFDFromFile:[self filename]];
        [scrollview setDocumentView:textView_];
                
        [self addSubview:scrollview];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setText:)
                                                     name:kToolNotesSetTextNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [textView_ writeRTFDToFile:[self filename] atomically:NO];
    [filemanager_ release];
    [super dealloc];
}

- (NSString *)filename
{
    return [NSString stringWithFormat:@"%@/notes.rtfd", [filemanager_ applicationSupportDirectory]];
}
         
- (void)textDidChange:(NSNotification *)aNotification
{
    // Avoid saving huge files because of the slowdown it would cause.
    if ([[textView_ textStorage] length] < 100 * 1024) {
        [textView_ writeRTFDToFile:[self filename] atomically:NO];
        ignoreNotification_ = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kToolNotesSetTextNotification
                                                            object:nil];
        ignoreNotification_ = NO;
    }
    [textView_ breakUndoCoalescing];
}

- (void)setText:(NSNotification *)aNotification
{
    if (!ignoreNotification_) {
        [textView_ readRTFDFromFile:[self filename]];
    }
}

- (void)shutdown {
}

@end
