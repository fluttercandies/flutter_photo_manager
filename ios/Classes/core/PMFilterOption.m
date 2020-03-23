//
// Created by Caijinglong on 2020/1/17.
//

#import "PMFilterOption.h"

@implementation PMFilterOptionGroup {
}

- (NSArray<NSSortDescriptor *> *)sortCond {
  PMDateOption *dateOption = self.dateOption;
  return @[
      [dateOption sortCond]
  ];
}

@end

@implementation PMFilterOption {

}
- (NSString *)sizeCond {
  return @"pixelWidth >= %d AND pixelWidth <=%d AND pixelHeight >= %d AND pixelHeight <=%d";
}

- (NSArray *)sizeArgs {
  PMSizeConstraint constraint = self.sizeConstraint;
  return @[@(constraint.minWidth), @(constraint.maxWidth), @(constraint.minHeight), @(constraint.maxHeight)];
}


- (NSString *)durationCond {
  return @"duration >= %f AND duration <= %f";
}

- (NSArray *)durationArgs {
  PMDurationConstraint constraint = self.durationConstraint;
  return @[@(constraint.minDuration), @(constraint.maxDuration)];
}

@end


@implementation PMDateOption {

}

- (NSString *)dateCond {
  return @"AND ( creationDate >= %@ AND creationDate <= %@ )";
}

- (NSArray *)dateArgs {
  return @[self.min, self.max];
}

- (NSSortDescriptor *)sortCond {
  return [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.asc];
}

@end