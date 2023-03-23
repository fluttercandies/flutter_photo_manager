//
// Created by jinglong cai on 2023/2/9.
//

#import <Foundation/Foundation.h>

@protocol PMBaseFilter <NSObject>

- (PHFetchOptions *)getFetchOptions:(int)type;

- (BOOL) containsModified;

- (BOOL) needTitle;

@end
