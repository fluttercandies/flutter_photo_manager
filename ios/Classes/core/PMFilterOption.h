#import <Foundation/Foundation.h>
#import "PMBaseFilter.h"

@interface PMDateOption : NSObject

@property(nonatomic, strong) NSDate *min;
@property(nonatomic, strong) NSDate *max;
@property(nonatomic, assign) BOOL ignore;

- (NSString *)dateCond:(NSString *)key;

- (NSArray *)dateArgs;

@end

typedef struct PMSizeConstraint {

  unsigned int minWidth;
  unsigned int maxWidth;
  unsigned int minHeight;
  unsigned int maxHeight;
  BOOL ignoreSize;

} PMSizeConstraint;

typedef struct PMDurationConstraint {

  double minDuration;
  double maxDuration;
  BOOL allowNullable;

} PMDurationConstraint;

@interface PMFilterOption : NSObject

@property(nonatomic, assign) BOOL needTitle;
@property(nonatomic, assign) PMSizeConstraint sizeConstraint;
@property(nonatomic, assign) PMDurationConstraint durationConstraint;

- (NSString *)sizeCond;

- (NSArray *)sizeArgs;

- (NSString *)durationCond;

- (NSArray *)durationArgs;

@end


@interface PMFilterOptionGroup : NSObject <PMBaseFilter>

@property(nonatomic, strong) PMFilterOption *imageOption;
@property(nonatomic, strong) PMFilterOption *videoOption;
@property(nonatomic, strong) PMFilterOption *audioOption;
@property(nonatomic, strong) PMDateOption *dateOption;
@property(nonatomic, strong) PMDateOption *updateOption;
@property(nonatomic, assign) BOOL containsLivePhotos;
@property(nonatomic, assign) BOOL onlyLivePhotos;
@property(nonatomic, assign) BOOL containsModified;
@property(nonatomic, assign) BOOL includeHiddenAssets;
@property(nonatomic, strong) NSArray<NSSortDescriptor *> *sortArray;

- (NSArray<NSSortDescriptor *> *)sortCond;

- (void)injectSortArray:(NSArray *)array;
@end


@interface PMCustomFilterOption : NSObject <PMBaseFilter>
@property (nonatomic, strong) NSDictionary *params;
@end
