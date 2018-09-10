//
// Created by Caijinglong on 2018/9/10.
//
#import <Flutter/FlutterChannels.h>
#import <Photos/PHPhotoLibrary.h>
#import <Photos/PHCollection.h>
#import "ImageScanner.h"

@implementation ImageScanner {


}
- (void)getImageIdList:(FlutterMethodCall *)call result:(FlutterResult)result {
//    PHPhotoLibrary *photoLibrary = [[PHPhotoLibrary alloc] init];
//    PHPhotoLibrary.sharedPhotoLibrary

    [PHCollectionList fetchCollectionsInCollectionList:<#(PHCollectionList *)collectionList#> options:<#(nullable PHFetchOptions *)options#>]
}

- (bool)requestPermission {
    if ([self isAuthoriztion]) {
        return true;
    }
    return false;
}

- (bool)isAuthoriztion {
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
        return TRUE;
    }
    return FALSE;
}

@end