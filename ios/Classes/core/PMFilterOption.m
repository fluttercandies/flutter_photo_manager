#import "PMFilterOption.h"

@implementation PMFilterOptionGroup {
}

- (NSArray<NSSortDescriptor *> *)sortCond {
    if (self.sortArray == nil || self.sortArray.count == 0) {
        return nil;
    }
    return self.sortArray;
}

- (void)injectSortArray:(NSArray *)array {
    NSMutableArray<NSSortDescriptor *> *result = [NSMutableArray new];
    
    // Handle platform default sorting first.
    if (array.count == 0) {
        // Set an empty sort array directly.
        self.sortArray = nil;
        return;
    }
    
    for (NSDictionary *dict in array) {
        int typeValue = [dict[@"type"] intValue];
        BOOL asc = [dict[@"asc"] boolValue];
        
        NSString *key = nil;
        if (typeValue == 0) {
            key = @"creationDate";
        } else if (typeValue == 1) {
            key = @"modificationDate";
        }
        
        if (key) {
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:asc];
            if (descriptor) {
                [result addObject:descriptor];
            }
        }
    }
    
    self.sortArray = result;
}
@end

@implementation PMFilterOption {
    
}
- (NSString *)sizeCond {
    return @"pixelWidth >=%d AND pixelWidth <=%d AND pixelHeight >=%d AND pixelHeight <=%d";
}

- (NSArray *)sizeArgs {
    PMSizeConstraint constraint = self.sizeConstraint;
    return @[@(constraint.minWidth), @(constraint.maxWidth), @(constraint.minHeight), @(constraint.maxHeight)];
}


- (NSString *)durationCond {
    NSString *baseCond = @"duration >= %f AND duration <= %f";
    if (self.durationConstraint.allowNullable) {
        return [NSString stringWithFormat:@"( duration == nil OR ( %@ ) )", baseCond];
    }
    return baseCond;
}

- (NSArray *)durationArgs {
    PMDurationConstraint constraint = self.durationConstraint;
    return @[@(constraint.minDuration), @(constraint.maxDuration)];
}

@end


@implementation PMDateOption {
    
}

- (NSString *)dateCond:(NSString *)key {
    NSMutableString *str = [NSMutableString new];
    
    [str appendString:@" AND "];
    [str appendString:@"( "];
    
    // min
    
    [str appendString:key];
    [str appendString:@" >= %@"];
    
    
    // and
    [str appendString:@" AND "];
    
    // max
    
    [str appendString:key];
    [str appendString:@" <= %@ "];
    
    [str appendString:@") "];
    
    return str;
}

- (NSArray *)dateArgs {
    return @[self.min, self.max];
}

@end
