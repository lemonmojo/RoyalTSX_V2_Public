//
//  TSVParser.h
//  iTerm
//
//  Created by George Nachman on 11/27/11.
//

#import <Cocoa/Cocoa.h>


@interface TSVDocument : NSObject {
    NSMutableArray *columns_;
    NSMutableArray *records_;
    NSMutableDictionary *map_;
}

@property (nonatomic, retain) NSMutableArray *columns;
@property (nonatomic, readonly) NSMutableArray *records;

- (NSString *)valueInRecord:(NSArray *)record forField:(NSString *)fieldName;

@end

@interface TSVParser : NSObject

+ (TSVDocument *)documentFromString:(NSString *)string withFields:(NSArray *)fields;

@end

@interface NSString (TSV)

- (TSVDocument *)tsvDocumentWithFields:(NSArray *)fields;

@end