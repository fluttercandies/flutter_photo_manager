//
// Created by Caijinglong on 2018/9/10.
//
#import <Flutter/FlutterChannels.h>
#import <Photos/PHPhotoLibrary.h>
#import <Photos/PHCollection.h>
#import <Photos/PHFetchOptions.h>
#import <Photos/PHImageManager.h>
#import <Photos/PHAsset.h>
#import "ImageScanner.h"
#import "MD5Utils.h"

@interface ImageScanner () <PHPhotoLibraryChangeObserver>

@property(nonatomic, strong) NSMutableArray<PHCollection *> *galleryArray;
@property(nonatomic, strong) NSMutableDictionary<NSString *, PHCollection *> *idCollectionDict;
@property(nonatomic, strong) NSMutableDictionary<NSString *, PHAsset *> *idAssetDict;

@property(nonatomic) dispatch_queue_t asyncQueue;
@end

@implementation ImageScanner {


}
- (void)requestPermissionWithResult:(FlutterResult)result {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
            result(@1);
        } else {
            result(@0);
        }
    }];

    self.asyncQueue = dispatch_queue_create("asyncQueue", nil);
}

- (void)getGalleryIdList:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        [self refreshGallery];
        NSMutableArray *arr = [NSMutableArray new];
        if (_idCollectionDict) {
            [_idCollectionDict removeAllObjects];
        } else {
            _idCollectionDict = [NSMutableDictionary new];
        }
        for (PHCollection *collection in _galleryArray) {
            [arr addObject:collection.localIdentifier];
            _idCollectionDict[collection.localIdentifier] = collection;
        }
        result(arr);
    });
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(_asyncQueue, ^{
        [self refreshGallery];
    });
}

- (void)refreshGallery {
    NSMutableArray<PHCollection *> *galleryArray = [NSMutableArray array];

    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];

    PHFetchResult *smartAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    PHAssetCollection *collection = [smartAlbumsFetchResult objectAtIndex:0];
    [galleryArray addObject:collection];

    PHFetchResult *smartAlbumsFetchResult1 = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:fetchOptions];
    for (PHAssetCollection *sub in smartAlbumsFetchResult1) {
        [galleryArray addObject:sub];
    }

    self.galleryArray = galleryArray;
}

- (void)getGalleryNameWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    dispatch_async(_asyncQueue, ^{
        NSArray *ids = call.arguments;
        NSMutableArray<NSString *> *r = [NSMutableArray new];
        for (NSString *id in ids) {
            PHCollection *collection = _idCollectionDict[id];
            [r addObject:collection.localizedTitle];
        }
        result(r);
    });
}

- (void)getImageListWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        if (_idAssetDict) {
            [_idAssetDict removeAllObjects];
        } else {
            _idAssetDict = [NSMutableDictionary new];
        }

        NSString *pathId = call.arguments;
        PHCollection *collection = _idCollectionDict[pathId];

        PHFetchOptions *opt = [PHFetchOptions new];
//    opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:true]];

        PHFetchResult<PHAssetCollection *> *r = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collection.localIdentifier] options:opt];

        NSMutableArray<NSString *> *arr = [NSMutableArray new];

        for (PHAssetCollection *assetCollection in r) {
            PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:opt];
            for (PHAsset *asset in fetchResult) {
                NSString *id = asset.localIdentifier;
                _idAssetDict[id] = asset;
                [arr addObject:id];
            }
        }

        flutterResult(arr);
    });
}

- (void)getThumbPathWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        PHImageManager *manager = PHImageManager.defaultManager;

        NSString *imgId = call.arguments;

        PHAsset *asset = _idAssetDict[imgId];

        [manager requestImageForAsset:asset targetSize:CGSizeMake(100, 100) contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions new] resultHandler:^(UIImage *result, NSDictionary *info) {
            NSData *data = UIImageJPEGRepresentation(result, 95);
            NSString *path = [self writeThumbFileWithAssetId:asset imageData:data];
            flutterResult(path);
        }];
    });
}

- (void)getThumbBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        PHImageManager *manager = PHImageManager.defaultManager;

        NSString *imgId = call.arguments;

        PHAsset *asset = self->_idAssetDict[imgId];

        [manager requestImageForAsset:asset targetSize:CGSizeMake(100, 100) contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions new] resultHandler:^(UIImage *result, NSDictionary *info) {
            NSData *data = UIImageJPEGRepresentation(result, 95);
            dispatch_async(self->_asyncQueue, ^{
                [self writeThumbFileWithAssetId:asset imageData:data];
            });
            NSArray *arr = [ImageScanner convertNSData:data];
            flutterResult(arr);
        }];
    });
}

- (NSString *)writeThumbFileWithAssetId:(PHAsset *)asset imageData:(NSData *)imageData {
    NSString *homePath = NSTemporaryDirectory();

//    NSURL *url = [[NSURL alloc] initWithString:homePath];

    NSFileManager *manager = NSFileManager.defaultManager;

    NSMutableString *path = [NSMutableString stringWithString:homePath];
    NSString *dir = [path stringByAppendingPathComponent:@".thumb"];

    BOOL createSuccess = [manager createDirectoryAtPath:dir attributes:nil];

    NSMutableString *p = [[NSMutableString alloc] initWithString:dir];
    NSString *filePath = [p stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [MD5Utils getmd5WithString:asset.localIdentifier]]];
    if ([manager fileExistsAtPath:filePath]) {
        return filePath;
    }

    BOOL createFileResult = [manager createFileAtPath:filePath contents:imageData attributes:nil];
    return filePath;
}

- (void)getFullFileWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        PHImageManager *manager = PHImageManager.defaultManager;

        NSString *imgId = call.arguments;

        PHAsset *asset = _idAssetDict[imgId];

        __weak ImageScanner *wSelf = self;

        [manager requestImageDataForAsset:asset options:[PHImageRequestOptions new] resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            NSString *path = [wSelf writeFullFileWithAssetId:asset imageData:imageData];
            flutterResult(path);
        }];
    });
}

- (NSString *)writeFullFileWithAssetId:(PHAsset *)asset imageData:(NSData *)imageData {
    NSString *homePath = NSTemporaryDirectory();
    NSFileManager *manager = NSFileManager.defaultManager;

    NSMutableString *path = [NSMutableString stringWithString:homePath];
    [path appendString:@".images"];

    BOOL createSuccess = [manager createDirectoryAtPath:path attributes:@{}];

    [path appendString:@"/"];
    [path appendString:[MD5Utils getmd5WithString:asset.localIdentifier]];
    [path appendString:@".jpg"];

    if ([manager fileExistsAtPath:path]) {
        return path;
    }

    [manager createFileAtPath:path contents:imageData attributes:@{}];
    return path;
}

- (void)getBytesWithCall:(FlutterMethodCall *)call result:(FlutterResult)flutterResult {
    dispatch_async(_asyncQueue, ^{
        NSString *imgId = call.arguments;
        PHAsset *asset = _idAssetDict[imgId];

        PHImageManager *manager = PHImageManager.defaultManager;
        [manager requestImageDataForAsset:asset options:[PHImageRequestOptions new] resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            NSArray *arr = [ImageScanner convertNSData:imageData];
            flutterResult(arr);
        }];
    });
}

+ (NSArray *)convertNSData:(NSData *)data {
    NSMutableArray *array = [NSMutableArray array];
    Byte *bytes = data.bytes;
    for (int i = 0; i < data.length; ++i) {
        [array addObject:@(bytes[i])];
    }
    return array;
}

+ (void)openSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
