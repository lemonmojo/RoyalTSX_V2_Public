/*
 **  ProfileModel.m
 **  iTerm
 **
 **  Created by George Nachman on 8/24/10.
 **  Project: iTerm
 **
 **  Description: Model for an ordered collection of bookmarks. Bookmarks have
 **    numerous attributes, but always have a name, set of tags, and a guid.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 */

#import "ITAddressBookMgr.h"
#import "ProfileModel.h"
#import "PreferencePanel.h"

id gAltOpenAllRepresentedObject;
// Set to true if a bookmark was changed automatically due to migration to a new
// standard.
int gMigrated;

@implementation ProfileModel

+ (void)initialize
{
    gAltOpenAllRepresentedObject = [[NSObject alloc] init];
}

+ (BOOL)migrated
{
    return gMigrated;
}

- (ProfileModel*)init
{
    self = [super init];
    if (self) {
        bookmarks_ = [[NSMutableArray alloc] init];
        defaultBookmarkGuid_ = @"";
        journal_ = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (ProfileModel*)sharedInstance
{
    static ProfileModel* shared = nil;

    if (!shared) {
        shared = [[ProfileModel alloc] init];
        shared->prefs_ = [NSUserDefaults standardUserDefaults];
        shared->postChanges_ = YES;
    }

    return shared;
}

+ (ProfileModel*)sessionsInstance
{
    static ProfileModel* shared = nil;

    if (!shared) {
        shared = [[ProfileModel alloc] init];
        shared->prefs_ = nil;
        shared->postChanges_ = NO;
    }

    return shared;
}

- (void)dealloc
{
    [super dealloc];
    [journal_ release];
    NSLog(@"Deallocating bookmark model!");
}

- (int)numberOfBookmarks
{
    return [bookmarks_ count];
}

- (BOOL)_document:(NSArray *)nameWords containsToken:(NSString *)token
{
    for (int k = 0; k < [nameWords count]; ++k) {
        NSString* tagPart = [nameWords objectAtIndex:k];
        NSRange range;
        if ([token length] && [token characterAtIndex:0] == '*') {
            range = [tagPart rangeOfString:[token substringFromIndex:1] options:NSCaseInsensitiveSearch];
        } else {
            range = [tagPart rangeOfString:token options:(NSCaseInsensitiveSearch | NSAnchoredSearch)];
        }
        if (range.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}
- (BOOL)doesBookmarkAtIndex:(int)theIndex matchFilter:(NSArray*)tokens
{
    Profile* bookmark = [self profileAtIndex:theIndex];
    NSArray* tags = [bookmark objectForKey:KEY_TAGS];
    NSArray* nameWords = [[bookmark objectForKey:KEY_NAME] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    for (int i = 0; i < [tokens count]; ++i) {
        NSString* token = [tokens objectAtIndex:i];
        if (![token length]) {
            continue;
        }
        // Search each word in tag until one has this token as a prefix.
        bool found;

        // First see if this token occurs in the title
        found = [self _document:nameWords containsToken:token];

        // If not try each tag.
        for (int j = 0; !found && j < [tags count]; ++j) {
            // Expand the jth tag into an array of the words in the tag
            NSArray* tagWords = [[tags objectAtIndex:j] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            found = [self _document:tagWords containsToken:token];
        }
        if (!found) {
            // No tag had token i as a prefix.
            return NO;
        }
    }
    return YES;
}

- (NSArray*)parseFilter:(NSString*)filter
{
    return [filter componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSArray*)bookmarkIndicesMatchingFilter:(NSString*)filter
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[bookmarks_ count]];
    NSArray* tokens = [self parseFilter:filter];
    int count = [bookmarks_ count];
    for (int i = 0; i < count; ++i) {
        if ([self doesBookmarkAtIndex:i matchFilter:tokens]) {
            [result addObject:[NSNumber numberWithInt:i]];
        }
    }
    return result;
}

- (int)numberOfBookmarksWithFilter:(NSString*)filter
{
    NSArray* tokens = [self parseFilter:filter];
    int count = [bookmarks_ count];
    int n = 0;
    for (int i = 0; i < count; ++i) {
        if ([self doesBookmarkAtIndex:i matchFilter:tokens]) {
            ++n;
        }
    }
    return n;
}

- (Profile*)profileAtIndex:(int)i
{
    if (i < 0 || i >= [bookmarks_ count]) {
        return nil;
    }
    return [bookmarks_ objectAtIndex:i];
}

- (Profile*)profileAtIndex:(int)theIndex withFilter:(NSString*)filter
{
    NSArray* tokens = [self parseFilter:filter];
    int count = [bookmarks_ count];
    int n = 0;
    for (int i = 0; i < count; ++i) {
        if ([self doesBookmarkAtIndex:i matchFilter:tokens]) {
            if (n == theIndex) {
                return [self profileAtIndex:i];
            }
            ++n;
        }
    }
    return nil;
}

- (void)addBookmark:(Profile*)bookmark
{
    [self addBookmark:bookmark inSortedOrder:NO];
}

+ (void)migratePromptOnCloseInMutableBookmark:(NSMutableDictionary *)dict
{
    // Migrate global "prompt on close" to per-profile prompt enum
    if ([dict objectForKey:KEY_PROMPT_CLOSE_DEPRECATED]) {
        // The 8/28 build incorrectly ignored the OnlyWhenMoreTabs setting
        // when migrating PromptOnClose to KEY_PRMOPT_CLOSE. Its preference
        // key has been changed to KEY_PROMPT_CLOSE_DEPRECATED and a new
        // pref key with the same intended usage has been added on 9/4 but
        // with a different name. If the setting is PROMPT_ALWAYS, then it may
        // have been migrated incorrectly. There are three ways to get here:
        // 1. PromptOnClose && OnlyWhenMoreTabs was migrated wrong.
        // 2. PromptOnClose && !OnlyWhenMoreTabs was migrated right.
        // 3. Post migration, the user set it to PROMPT_ALWAYS
        //
        // For case 1, redoing the migration produces the correct result.
        // For case 2, redoing the migration has no effect.
        // For case 3, the user's pref is overwritten. This should be rare.
        int value = [[dict objectForKey:KEY_PROMPT_CLOSE_DEPRECATED] intValue];
        if (value != PROMPT_ALWAYS) {
            [dict setObject:[NSNumber numberWithInt:value]
                     forKey:KEY_PROMPT_CLOSE];
        }
    }
    if (![dict objectForKey:KEY_PROMPT_CLOSE]) {
        BOOL promptOnClose = [[[NSUserDefaults standardUserDefaults] objectForKey:@"PromptOnClose"] boolValue];
        NSNumber *onlyWhenNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"OnlyWhenMoreTabs"];
        if (!onlyWhenNumber || [onlyWhenNumber boolValue]) {
            promptOnClose = NO;
        }

        NSNumber *newValue = [NSNumber numberWithBool:promptOnClose ? PROMPT_ALWAYS : PROMPT_NEVER];
        [dict setObject:newValue forKey:KEY_PROMPT_CLOSE];
        gMigrated = YES;
    }

    // This is a required field to avoid setting nil values in the bookmark
    // dict later on.
    if (![dict objectForKey:KEY_JOBS]) {
        [dict setObject:[NSArray arrayWithObjects:@"rlogin", @"ssh", @"slogin", @"telnet", nil]
                 forKey:KEY_JOBS];
        gMigrated = YES;
    }
}

- (void)addBookmark:(Profile*)bookmark inSortedOrder:(BOOL)sort
{

    NSMutableDictionary *newBookmark = [[bookmark mutableCopy] autorelease];

    // Ensure required fields are present
    if (![newBookmark objectForKey:KEY_NAME]) {
        [newBookmark setObject:@"Bookmark" forKey:KEY_NAME];
    }
    if (![newBookmark objectForKey:KEY_TAGS]) {
        [newBookmark setObject:[NSArray arrayWithObjects:nil] forKey:KEY_TAGS];
    }
    if (![newBookmark objectForKey:KEY_CUSTOM_COMMAND]) {
        [newBookmark setObject:@"No" forKey:KEY_CUSTOM_COMMAND];
    }
    if (![newBookmark objectForKey:KEY_COMMAND]) {
        [newBookmark setObject:@"/bin/bash --login" forKey:KEY_COMMAND];
    }
    if (![newBookmark objectForKey:KEY_GUID]) {
        [newBookmark setObject:[ProfileModel freshGuid] forKey:KEY_GUID];
    }
    if (![newBookmark objectForKey:KEY_DEFAULT_BOOKMARK]) {
        [newBookmark setObject:@"No" forKey:KEY_DEFAULT_BOOKMARK];
    }
    [ProfileModel migratePromptOnCloseInMutableBookmark:newBookmark];

    bookmark = [[newBookmark copy] autorelease];

    int theIndex;
    if (sort) {
        // Insert alphabetically. Sort so that objects with the "bonjour" tag come after objects without.
        int insertionPoint = -1;
        NSString* newName = [bookmark objectForKey:KEY_NAME];
        BOOL hasBonjour = [self bookmark:bookmark hasTag:@"bonjour"];
        for (int i = 0; i < [bookmarks_ count]; ++i) {
            Profile* bookmarkAtI = [bookmarks_ objectAtIndex:i];
            NSComparisonResult order = NSOrderedSame;
            BOOL currentHasBonjour = [self bookmark:bookmarkAtI hasTag:@"bonjour"];
            if (hasBonjour != currentHasBonjour) {
                if (hasBonjour) {
                    order = NSOrderedAscending;
                } else {
                    order = NSOrderedDescending;
                }
            }
            if (order == NSOrderedSame) {
                order = [[[bookmarks_ objectAtIndex:i] objectForKey:KEY_NAME] caseInsensitiveCompare:newName];
            }
            if (order == NSOrderedDescending) {
                insertionPoint = i;
                break;
            }
        }
        if (insertionPoint == -1) {
            theIndex = [bookmarks_ count];
            [bookmarks_ addObject:[NSDictionary dictionaryWithDictionary:bookmark]];
        } else {
            theIndex = insertionPoint;
            [bookmarks_ insertObject:[NSDictionary dictionaryWithDictionary:bookmark] atIndex:insertionPoint];
        }
    } else {
        theIndex = [bookmarks_ count];
        [bookmarks_ addObject:[NSDictionary dictionaryWithDictionary:bookmark]];
    }
    NSString* isDeprecatedDefaultBookmark = [bookmark objectForKey:KEY_DEFAULT_BOOKMARK];

    // The call to setDefaultByGuid may add a journal entry so make sure this one comes first.
    BookmarkJournalEntry* e = [BookmarkJournalEntry journalWithAction:JOURNAL_ADD bookmark:bookmark model:self];
    e->index = theIndex;
    [journal_ addObject:e];

    if (![self defaultBookmark] || (isDeprecatedDefaultBookmark && [isDeprecatedDefaultBookmark isEqualToString:@"Yes"])) {
        [self setDefaultByGuid:[bookmark objectForKey:KEY_GUID]];
    }
    [self postChangeNotification];
}

- (BOOL)bookmark:(Profile*)bookmark hasTag:(NSString*)tag
{
    NSArray* tags = [bookmark objectForKey:KEY_TAGS];
    return [tags containsObject:tag];
}

- (int)convertFilteredIndex:(int)theIndex withFilter:(NSString*)filter
{
    NSArray* tokens = [self parseFilter:filter];
    int count = [bookmarks_ count];
    int n = 0;
    for (int i = 0; i < count; ++i) {
        if ([self doesBookmarkAtIndex:i matchFilter:tokens]) {
            if (n == theIndex) {
                return i;
            }
            ++n;
        }
    }
    return -1;
}

- (void)removeBookmarksAtIndices:(NSArray*)indices
{
    NSArray* sorted = [indices sortedArrayUsingSelector:@selector(compare:)];
    for (int j = [sorted count] - 1; j >= 0; j--) {
        int i = [[sorted objectAtIndex:j] intValue];
        assert(i >= 0);

        [journal_ addObject:[BookmarkJournalEntry journalWithAction:JOURNAL_REMOVE bookmark:[bookmarks_ objectAtIndex:i] model:self]];
        [bookmarks_ removeObjectAtIndex:i];
        if (![self defaultBookmark] && [bookmarks_ count]) {
            [self setDefaultByGuid:[[bookmarks_ objectAtIndex:0] objectForKey:KEY_GUID]];
        }
    }
    [self postChangeNotification];
}

- (void)removeBookmarkAtIndex:(int)i
{
    assert(i >= 0);
    [journal_ addObject:[BookmarkJournalEntry journalWithAction:JOURNAL_REMOVE bookmark:[bookmarks_ objectAtIndex:i] model:self]];
    [bookmarks_ removeObjectAtIndex:i];
    if (![self defaultBookmark] && [bookmarks_ count]) {
        [self setDefaultByGuid:[[bookmarks_ objectAtIndex:0] objectForKey:KEY_GUID]];
    }
    [self postChangeNotification];
}

- (void)removeBookmarkAtIndex:(int)i withFilter:(NSString*)filter
{
    [self removeBookmarkAtIndex:[self convertFilteredIndex:i withFilter:filter]];
}

- (void)removeBookmarkWithGuid:(NSString*)guid
{
    int i = [self indexOfProfileWithGuid:guid];
    if (i >= 0) {
        [self removeBookmarkAtIndex:i];
    }
}

// A change in bookmarks is journal-worthy only if the name, shortcut, tags, or guid changes.
- (BOOL)bookmark:(Profile*)a differsJournalablyFrom:(Profile*)b
{
    // Any field that is shown in a view (profiles window, menus, bookmark list views, etc.) must
    // be a criteria for journalability for it to be updated immediately.
    if (![[a objectForKey:KEY_NAME] isEqualToString:[b objectForKey:KEY_NAME]] ||
        ![[a objectForKey:KEY_SHORTCUT] isEqualToString:[b objectForKey:KEY_SHORTCUT]] ||
        ![[a objectForKey:KEY_TAGS] isEqualToArray:[b objectForKey:KEY_TAGS]] ||
        ![[a objectForKey:KEY_GUID] isEqualToString:[b objectForKey:KEY_GUID]] ||
        ![[a objectForKey:KEY_COMMAND] isEqualToString:[b objectForKey:KEY_COMMAND]] ||
        ![[a objectForKey:KEY_CUSTOM_COMMAND] isEqualToString:[b objectForKey:KEY_CUSTOM_COMMAND]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setBookmark:(Profile*)bookmark atIndex:(int)i
{
    Profile* orig = [bookmarks_ objectAtIndex:i];
    BOOL isDefault = NO;
    if ([[orig objectForKey:KEY_GUID] isEqualToString:defaultBookmarkGuid_]) {
        isDefault = YES;
    }

    Profile* before = [bookmarks_ objectAtIndex:i];
    BOOL needJournal = [self bookmark:bookmark differsJournalablyFrom:before];
    if (needJournal) {
        [journal_ addObject:[BookmarkJournalEntry journalWithAction:JOURNAL_REMOVE bookmark:[bookmarks_ objectAtIndex:i] model:self]];
    }
    [bookmarks_ replaceObjectAtIndex:i withObject:bookmark];
    if (needJournal) {
        BookmarkJournalEntry* e = [BookmarkJournalEntry journalWithAction:JOURNAL_ADD bookmark:bookmark model:self];
        e->index = i;
        [journal_ addObject:e];
    }
    if (isDefault) {
        [self setDefaultByGuid:[bookmark objectForKey:KEY_GUID]];
    }
    if (needJournal) {
        [self postChangeNotification];
    }
}

- (void)setBookmark:(Profile*)bookmark withGuid:(NSString*)guid
{
    int i = [self indexOfProfileWithGuid:guid];
    if (i >= 0) {
        [self setBookmark:bookmark atIndex:i];
    }
}

- (void)removeAllBookmarks
{
    [bookmarks_ removeAllObjects];
    defaultBookmarkGuid_ = @"";
    [journal_ addObject:[BookmarkJournalEntry journalWithAction:JOURNAL_REMOVE_ALL bookmark:nil model:self]];
    [self postChangeNotification];
}

- (NSArray*)rawData
{
    return bookmarks_;
}

- (void)load:(NSArray*)prefs
{
    [bookmarks_ removeAllObjects];
    for (int i = 0; i < [prefs count]; ++i) {
        Profile* bookmark = [prefs objectAtIndex:i];
        NSArray* tags = [bookmark objectForKey:KEY_TAGS];
        if (![tags containsObject:@"bonjour"]) {
            [self addBookmark:bookmark];
        }
    }
    [bookmarks_ retain];
}

+ (NSString*)freshGuid
{
    CFUUIDRef uuidObj = CFUUIDCreate(nil); //create a new UUID
    //get the string representation of the UUID
    NSString *uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return [uuidString autorelease];
}

- (int)indexOfProfileWithGuid:(NSString*)guid
{
    return [self indexOfProfileWithGuid:guid withFilter:@""];
}

- (int)indexOfProfileWithGuid:(NSString*)guid withFilter:(NSString*)filter
{
    NSArray* tokens = [self parseFilter:filter];
    int count = [bookmarks_ count];
    int n = 0;
    for (int i = 0; i < count; ++i) {
        if (![self doesBookmarkAtIndex:i matchFilter:tokens]) {
            continue;
        }
        if ([[[bookmarks_ objectAtIndex:i] objectForKey:KEY_GUID] isEqualToString:guid]) {
            return n;
        }
        ++n;
    }
    return -1;
}

- (Profile*)defaultBookmark
{
    return [self bookmarkWithGuid:defaultBookmarkGuid_];
}

- (Profile*)bookmarkWithName:(NSString*)name
{
    int count = [bookmarks_ count];
    for (int i = 0; i < count; ++i) {
        if ([[[bookmarks_ objectAtIndex:i] objectForKey:KEY_NAME] isEqualToString:name]) {
            return [bookmarks_ objectAtIndex:i];
        }
    }
    return nil;
}

- (Profile*)bookmarkWithGuid:(NSString*)guid
{
    int count = [bookmarks_ count];
    for (int i = 0; i < count; ++i) {
        if ([[[bookmarks_ objectAtIndex:i] objectForKey:KEY_GUID] isEqualToString:guid]) {
            return [bookmarks_ objectAtIndex:i];
        }
    }
    return nil;
}

- (int)indexOfBookmarkWithName:(NSString*)name
{
    int count = [bookmarks_ count];
    for (int i = 0; i < count; ++i) {
        if ([[[bookmarks_ objectAtIndex:i] objectForKey:KEY_NAME] isEqualToString:name]) {
            return i;
        }
    }
    return -1;
}

- (NSArray*)allTags
{
    NSMutableDictionary* temp = [[[NSMutableDictionary alloc] init] autorelease];
    for (int i = 0; i < [self numberOfBookmarks]; ++i) {
        Profile* bookmark = [self profileAtIndex:i];
        NSArray* tags = [bookmark objectForKey:KEY_TAGS];
        for (int j = 0; j < [tags count]; ++j) {
            NSString* tag = [tags objectAtIndex:j];
            [temp setObject:@"" forKey:tag];
        }
    }
    return [temp allKeys];
}

- (Profile*)setObject:(id)object forKey:(NSString*)key inBookmark:(Profile*)bookmark
{
    NSMutableDictionary* newDict = [NSMutableDictionary dictionaryWithDictionary:bookmark];
    if (object == nil) {
        [newDict removeObjectForKey:key];
    } else {
        [newDict setObject:object forKey:key];
    }
    NSString* guid = [bookmark objectForKey:KEY_GUID];
    Profile* newBookmark = [NSDictionary dictionaryWithDictionary:newDict];
    [self setBookmark:newBookmark
             withGuid:guid];
    return newBookmark;
}

- (void)setDefaultByGuid:(NSString*)guid
{
    [guid retain];
    [defaultBookmarkGuid_ release];
    defaultBookmarkGuid_ = guid;
    if (prefs_) {
        [prefs_ setObject:defaultBookmarkGuid_ forKey:KEY_DEFAULT_GUID];
    }
    [journal_ addObject:[BookmarkJournalEntry journalWithAction:JOURNAL_SET_DEFAULT
                                                       bookmark:[self defaultBookmark]
                                                          model:self]];
    [self postChangeNotification];
}

- (void)moveGuid:(NSString*)guid toRow:(int)destinationRow
{
    int sourceRow = [self indexOfProfileWithGuid:guid];
    if (sourceRow < 0) {
        return;
    }
    Profile* bookmark = [bookmarks_ objectAtIndex:sourceRow];
    [bookmark retain];
    [bookmarks_ removeObjectAtIndex:sourceRow];
    if (sourceRow < destinationRow) {
        destinationRow--;
    }
    [bookmarks_ insertObject:bookmark atIndex:destinationRow];
    [bookmark release];
}

- (void)rebuildMenus
{
    [journal_ addObject:[BookmarkJournalEntry journalWithAction:JOURNAL_REMOVE_ALL bookmark:nil model:self]];
    int i = 0;
    for (Profile* b in bookmarks_) {
        BookmarkJournalEntry* e = [BookmarkJournalEntry journalWithAction:JOURNAL_ADD bookmark:b model:self];
        e->index = i++;
        [journal_ addObject:e];
    }
    [self postChangeNotification];
}

- (void)postChangeNotification
{
    if (postChanges_) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"iTermReloadAddressBook"
                                                            object:nil
                                                          userInfo:[NSDictionary dictionaryWithObject:journal_ forKey:@"array"]];
    }
    [journal_ release];
    journal_ = [[NSMutableArray alloc] init];
}

- (void)dump
{
    for (int i = 0; i < [self numberOfBookmarks]; ++i) {
        Profile* bookmark = [self profileAtIndex:i];
        NSLog(@"%d: %@ %@", i, [bookmark objectForKey:KEY_NAME], [bookmark objectForKey:KEY_GUID]);
    }
}

- (NSArray*)bookmarks
{
    return bookmarks_;
}

- (NSArray*)guids
{
    NSMutableArray* guids = [NSMutableArray arrayWithCapacity:[bookmarks_ count]];
    for (Profile* bookmark in bookmarks_) {
        [guids addObject:[bookmark objectForKey:KEY_GUID]];
    }
    return guids;
}

+ (NSMenu*)findOrCreateTagSubmenuInMenu:(NSMenu*)menu startingAtItem:(int)skip withName:(NSString*)name params:(JournalParams*)params
{
    NSArray* items = [menu itemArray];
    int pos = [menu numberOfItems];
    int N = pos;
    for (int i = skip; i < N; i++) {
        NSMenuItem* cur = [items objectAtIndex:i];
        if (![cur submenu] || [cur isSeparatorItem]) {
            pos = i;
            break;
        }
        int comp = [[cur title] caseInsensitiveCompare:name];
        if (comp == 0) {
            return [cur submenu];
        } else if (comp > 0) {
            pos = i;
            break;
        }
    }

    // Add menu item with submenu
    NSMenuItem* newItem = [[[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""] autorelease];
    [newItem setSubmenu:[[[NSMenu alloc] init] autorelease]];
    [menu insertItem:newItem atIndex:pos];

    return [newItem submenu];
}

+ (void)addOpenAllToMenu:(NSMenu*)menu params:(JournalParams*)params
{
    // Add separator + open all menu items
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem* openAll = [menu addItemWithTitle:@"Open All" action:params->openAllSelector keyEquivalent:@""];
    [openAll setTarget:params->target];

    // Add alternate open all menu
    NSMenuItem* altOpenAll = [[NSMenuItem alloc] initWithTitle:@"Open All in New Window"
                                                        action:params->alternateOpenAllSelector
                                                 keyEquivalent:@""];
    [altOpenAll setTarget:params->target];
    [altOpenAll setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [altOpenAll setAlternate:YES];
    [altOpenAll setRepresentedObject:gAltOpenAllRepresentedObject];
    [menu addItem:altOpenAll];
    [altOpenAll release];
}

+ (BOOL)menuHasOpenAll:(NSMenu*)menu
{
    NSArray* items = [menu itemArray];
    if ([items count] < 3) {
        return NO;
    }
    int n = [items count];
    return ([[items objectAtIndex:n-1] representedObject] == gAltOpenAllRepresentedObject);
}

- (int)positionOfBookmark:(Profile*)b startingAtItem:(int)skip inMenu:(NSMenu*)menu
{
    // Find position of bookmark in menu
    NSString* name = [b objectForKey:KEY_NAME];
    int N = [menu numberOfItems];
    if ([ProfileModel menuHasOpenAll:menu]) {
        N -= 3;
    }
    NSArray* items = [menu itemArray];
    int pos = N;
    for (int i = skip; i < N; i++) {
        NSMenuItem* cur = [items objectAtIndex:i];
        if ([cur isSeparatorItem]) {
            break;
        }
        if ([cur isHidden] || [cur submenu]) {
            continue;
        }
        if ([[cur title] caseInsensitiveCompare:name] > 0) {
            pos = i;
            break;
        }
    }

    return pos;
}

- (int)positionOfBookmarkWithIndex:(int)theIndex startingAtItem:(int)skip inMenu:(NSMenu*)menu
{
    // Find position of bookmark in menu
    int N = [menu numberOfItems];
    if ([ProfileModel menuHasOpenAll:menu]) {
        N -= 3;
    }
    NSArray* items = [menu itemArray];
    int pos = N;
    for (int i = skip; i < N; i++) {
        NSMenuItem* cur = [items objectAtIndex:i];
        if ([cur isSeparatorItem]) {
            break;
        }
        if ([cur isHidden] || [cur submenu]) {
            continue;
        }
        if ([cur tag] > theIndex) {
            pos = i;
            break;
        }
    }

    return pos;
}

- (void)addBookmark:(Profile*)b
             toMenu:(NSMenu*)menu
         atPosition:(int)pos
         withParams:(JournalParams*)params
        isAlternate:(BOOL)isAlternate
            withTag:(int)tag
{
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[b objectForKey:KEY_NAME]
                                                  action:isAlternate ? params->alternateSelector : params->selector
                                           keyEquivalent:@""];
    NSString* shortcut = [b objectForKey:KEY_SHORTCUT];
    if ([shortcut length]) {
        [item setKeyEquivalent:[shortcut lowercaseString]];
        [item setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask | (isAlternate ? NSAlternateKeyMask : 0)];
    } else if (isAlternate) {
        [item setKeyEquivalentModifierMask:NSAlternateKeyMask];
    }
    [item setAlternate:isAlternate];
    [item setTarget:params->target];
    [item setRepresentedObject:[[[b objectForKey:KEY_GUID] copy] autorelease]];
    [item setTag:tag];
    [menu insertItem:item atIndex:pos];
    [item release];
}

- (void)addBookmark:(Profile*)b toMenu:(NSMenu*)menu startingAtItem:(int)skip withTags:(NSArray*)tags params:(JournalParams*)params atPos:(int)theIndex
{
    int pos;
    if (theIndex == -1) {
        // Add in sorted order
        pos = [self positionOfBookmark:b startingAtItem:skip inMenu:menu];
    } else {
        pos = [self positionOfBookmarkWithIndex:theIndex startingAtItem:skip inMenu:menu];
    }

    if (![tags count]) {
        // Add item & alternate if no tags
        [self addBookmark:b toMenu:menu atPosition:pos withParams:params isAlternate:NO withTag:theIndex];
        [self addBookmark:b toMenu:menu atPosition:pos+1 withParams:params isAlternate:YES withTag:theIndex];
    }

    // Add to tag submenus
    for (NSString* tag in [NSSet setWithArray:tags]) {
        NSMenu* tagSubMenu = [ProfileModel findOrCreateTagSubmenuInMenu:menu
                                                          startingAtItem:skip
                                                                withName:tag
                                                                  params:params];
        [self addBookmark:b toMenu:tagSubMenu startingAtItem:0 withTags:nil params:params atPos:theIndex];
    }

    if ([menu numberOfItems] > skip + 2 && ![ProfileModel menuHasOpenAll:menu]) {
        [ProfileModel addOpenAllToMenu:menu params:params];
    }
}

+ (void)applyAddJournalEntry:(BookmarkJournalEntry*)e toMenu:(NSMenu*)menu startingAtItem:(int)skip params:(JournalParams*)params
{
    ProfileModel* model = e->model;
    Profile* b = [model bookmarkWithGuid:e->guid];
    if (!b) {
        return;
    }
    [model addBookmark:b toMenu:menu startingAtItem:skip withTags:[b objectForKey:KEY_TAGS] params:params atPos:e->index];
}

+ (void)applyRemoveJournalEntry:(BookmarkJournalEntry*)e toMenu:(NSMenu*)menu startingAtItem:(int)skip params:(JournalParams*)params
{
    int pos = [menu indexOfItemWithRepresentedObject:e->guid];
    if (pos != -1) {
        [menu removeItemAtIndex:pos];
        [menu removeItemAtIndex:pos];
    }

    // Remove bookmark from each tag it belongs to
    for (NSString* tag in e->tags) {
        NSMenuItem* item = [menu itemWithTitle:tag];
        NSMenu* submenu = [item submenu];
        if (submenu) {
            [ProfileModel applyRemoveJournalEntry:e toMenu:submenu startingAtItem:0 params:params];
            if ([submenu numberOfItems] == 0) {
                [menu removeItem:item];
            }
        }
    }

    // Remove "open all" section if it's no longer needed.
    // [0, ..., skip-1, bm1, bm1alt, separator, open all, open all alternate]
    if (([ProfileModel menuHasOpenAll:menu] && [menu numberOfItems] <= skip + 5)) {
        [menu removeItemAtIndex:[menu numberOfItems] - 1];
        [menu removeItemAtIndex:[menu numberOfItems] - 1];
        [menu removeItemAtIndex:[menu numberOfItems] - 1];
    }
}

+ (void)applyRemoveAllJournalEntry:(BookmarkJournalEntry*)e toMenu:(NSMenu*)menu startingAtItem:(int)skip params:(JournalParams*)params
{
    while ([menu numberOfItems] > skip) {
        [menu removeItemAtIndex:[menu numberOfItems] - 1];
    }
}

+ (void)applySetDefaultJournalEntry:(BookmarkJournalEntry*)e toMenu:(NSMenu*)menu startingAtItem:(int)skip params:(JournalParams*)params
{
}

+ (void)applyJournal:(NSDictionary*)journalDict toMenu:(NSMenu*)menu startingAtItem:(int)skip params:(JournalParams*)params
{
    NSArray* journal = [journalDict objectForKey:@"array"];
    for (BookmarkJournalEntry* e in journal) {
        switch (e->action) {
            case JOURNAL_ADD:
                [ProfileModel applyAddJournalEntry:e toMenu:menu startingAtItem:skip params:params];
                break;

            case JOURNAL_REMOVE:
                [ProfileModel applyRemoveJournalEntry:e toMenu:menu startingAtItem:skip params:params];
                break;

            case JOURNAL_REMOVE_ALL:
                [ProfileModel applyRemoveAllJournalEntry:e toMenu:menu startingAtItem:skip params:params];
                break;

            case JOURNAL_SET_DEFAULT:
                [ProfileModel applySetDefaultJournalEntry:e toMenu:menu startingAtItem:skip params:params];
                break;

            default:
                assert(false);
        }
    }
}

+ (void)applyJournal:(NSDictionary*)journal toMenu:(NSMenu*)menu params:(JournalParams*)params
{
    [ProfileModel applyJournal:journal toMenu:menu startingAtItem:0 params:params];
}


@end

@implementation BookmarkJournalEntry


+ (BookmarkJournalEntry*)journalWithAction:(JournalAction)action
                                  bookmark:(Profile*)bookmark
                                     model:(ProfileModel*)model
{
    BookmarkJournalEntry* entry = [[[BookmarkJournalEntry alloc] init] autorelease];
    entry->action = action;
    entry->guid = [[bookmark objectForKey:KEY_GUID] copy];
    entry->model = model;
    entry->tags = [[NSArray alloc] initWithArray:[bookmark objectForKey:KEY_TAGS]];
    return entry;
}

- (void)dealloc
{
    [guid release];
    [tags release];
    [super dealloc];
}

@end
