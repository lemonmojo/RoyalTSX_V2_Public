// TOMORROW: test that everything with affinities works.

//
//  EquivalenceClassSet.m
//  iTerm
//
//  Created by George Nachman on 12/28/11.
//  Copyright (c) 2011 Georgetech. All rights reserved.
//

#import "EquivalenceClassSet.h"

@implementation EquivalenceClassSet

- (id)init
{
    self = [super init];
    if (self) {
        index_ = [[NSMutableDictionary alloc] init];
        classes_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [index_ release];
    [classes_ release];
    [super dealloc];
}

- (NSArray *)valuesEqualTo:(NSObject *)target
{
    NSNumber *ec = [index_ objectForKey:target];
    return ec ? [classes_ objectForKey:ec] : nil;
}

- (void)addValue:(NSObject *)value toClass:(NSNumber *)ec
{
    [self removeValue:value];
    [index_ setObject:ec forKey:value];
    NSMutableSet *theSet = [classes_ objectForKey:ec];
    if (!theSet) {
        theSet = [NSMutableSet set];
        [classes_ setObject:theSet forKey:ec];
    }
    [theSet addObject:value];
}

- (NSNumber *)addEquivalenceClass
{
    int i = 0;
    while ([classes_ objectForKey:[NSNumber numberWithInt:i]]) {
        i++;
    }
    return [NSNumber numberWithInt:i];
}

- (void)setValue:(NSObject *)n1 equalToValue:(NSObject *)n2
{
    NSNumber *n1Class = [index_ objectForKey:n1];
    NSNumber *n2Class = [index_ objectForKey:n2];
    if (n1Class) {
        if (n2Class) {
            if ([n1Class intValue] != [n2Class intValue]) {
                // Merge the equivalence classes. Move every value in n2's class
                // (including n2, of course) into n1's.
                for (NSNumber *n in [[[classes_ objectForKey:n2Class] copy] autorelease]) {
                    [self addValue:n toClass:n1Class];
                }
            }
        } else {
            // n2 does not belong to an existing equiv class yet so add it to n1's class
            [self addValue:n2 toClass:n1Class];
        }
    } else {
        // n1 does not have an equiv relation yet
        if (n2Class) {
            // n2 has an equiv relation already so add n1 to it
            [self addValue:n1 toClass:n2Class];
        } else {
            // Neither n1 nor n2 has an existing relation so create a new equivalence class
            NSNumber *ec = [self addEquivalenceClass];
            [self addValue:n2 toClass:ec];
            [self addValue:n1 toClass:ec];
        }
    }
}

- (void)removeValue:(NSObject *)target
{
    NSNumber *ec = [index_ objectForKey:target];
    if (!ec) {
        return;
    }
    NSMutableSet *c = [classes_ objectForKey:ec];
    [c removeObject:target];
    [index_ removeObjectForKey:target];
    if (!c.count) {
        [classes_ removeObjectForKey:ec];
    } else if (c.count == 1) {
        // An equivalence class with one object is silly so remove its last element.
        [self removeValue:[[c allObjects] lastObject]];
    }
}

- (NSArray *)classes
{
	return [classes_ allValues];
}

@end
