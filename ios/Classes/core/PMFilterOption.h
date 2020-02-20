//
// Created by Caijinglong on 2020/1/17.
//

#import <Foundation/Foundation.h>

typedef struct PMSizeConstraint {

    unsigned int minWidth;
    unsigned int maxWidth;
    unsigned int minHeight;
    unsigned int maxHeight;

} PMSizeConstraint;

typedef struct PMDurationConstraint {

    double minDuration;
    double maxDuration;

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

@interface PMFilterOptionGroup : NSObject

@property(nonatomic, strong) PMFilterOption *imageOption;
@property(nonatomic, strong) PMFilterOption *videoOption;

@end