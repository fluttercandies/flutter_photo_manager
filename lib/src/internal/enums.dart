// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:math' as math;

/// {@template photo_manager.AssetType}
/// The type of the asset.
///
/// Most of assets are [AssetType.image] and [AssetType.video],
/// some assets might be [AssetType.audio] on Android.
/// The [AssetType.other] type won't show in general.
/// {@endtemplate}
///
/// **IMPORTANT FOR MAINTAINERS:** **DO NOT** change orders of values.
enum AssetType {
  /// The asset is not an image, video, or audio file.
  other,

  /// The asset is an image file.
  image,

  /// The asset is a video file.
  video,

  /// The asset is an audio file.
  audio,
}

/// {@template photo_manager.ThumbnailFormat}
/// Which format the thumbnail should be, generally support JPG and PNG.
/// {@endtemplate}
enum ThumbnailFormat { jpeg, png }

/// Enumeration for `PHImageRequestOptionsDeliveryMode` on iOS/macOS.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phimagerequestoptionsdeliverymode)
enum DeliveryMode { opportunistic, highQualityFormat, fastFormat }

/// Specifies how to resize the requested image on iOS/macOS.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phimagerequestoptions/1616988-resizemode)
enum ResizeMode { none, fast, exact }

/// Fitting an image’s aspect ratio to a requested size on iOS/macOS.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phimagecontentmode)
enum ResizeContentMode { fit, fill, def }

/// An enumeration of possible options for sorting asset lists.
enum OrderOptionType {
  /// Sorts assets by their creation date.
  createDate,

  /// Sorts assets by their modification date.
  updateDate,
}

/// {@template photo_manager.PMRequestState}
/// Indicate the current state when an asset is loading with [PMProgressHandler].
/// {@endtemplate}
enum PMRequestState { prepare, loading, success, failed }

/// Information about app’s authorization to access the user’s photo library.
///
/// Possible values for platforms:
///  * Android: [authorized], [denied], and [limited].
///  * iOS/macOS: All.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phauthorizationstatus)
enum PermissionState {
  /// The user has not set the app’s authorization status.
  notDetermined,

  /// The app isn’t authorized to access the photo library,
  /// and the user can’t grant such permission.
  restricted,

  /// The user explicitly denied this app access to the photo library.
  denied,

  /// The user explicitly granted this app access to the photo library.
  authorized,

  /// The user authorized this app for limited photo library access.
  limited,
}

/// The app’s level of access to the user’s photo library.
///
/// See also:
///  * [Apple documentation](https://developer.apple.com/documentation/photokit/phaccesslevel)
enum IosAccessLevel {
  /// The user can only add photos to the library.
  addOnly,

  /// The user can read from and write to the photo library.
  readWrite,
}

/// Common file types for images.
enum ImageFileType {
  /// The image is a JPEG file.
  jpg,

  /// The image is a PNG file.
  png,

  /// The image is a GIF file.
  gif,

  /// The image is a TIFF file.
  tiff,

  /// The image is an HEIC file.
  heic,

  /// The image is another type of file.
  other,
}

/// An enumeration of special image types.
enum SpecialImageType {
  /// The image is a GIF file.
  gif,

  /// The image is an HEIC file.
  heic,
}

/// The type of PHAssetCollection.
///
/// See document: https://developer.apple.com/documentation/photokit/phassetcollectiontype
///
/// The moment type is deprecated in iOS 13, so we don't support it.
enum PMDarwinAssetCollectionType {
  album,
  smartAlbum,
}

extension PMDarwinAssetCollectionTypeExt on PMDarwinAssetCollectionType {
  int get value {
    switch (this) {
      case PMDarwinAssetCollectionType.album:
        return 1;
      case PMDarwinAssetCollectionType.smartAlbum:
        return 2;
    }
  }

  static PMDarwinAssetCollectionType? fromValue(int? value) {
    switch (value) {
      case 1:
        return PMDarwinAssetCollectionType.album;
      case 2:
        return PMDarwinAssetCollectionType.smartAlbum;
    }

    return null;
  }
}

/// See document: https://developer.apple.com/documentation/photokit/phassetcollectionsubtype
///
/// The define of the subtype of the collection.
///
/// ```objc
/// typedef NS_ENUM(NSInteger, PHAssetCollectionSubtype) {
///
///     // PHAssetCollectionTypeAlbum regular subtypes
///     PHAssetCollectionSubtypeAlbumRegular         = 2,
///     PHAssetCollectionSubtypeAlbumSyncedEvent     = 3,
///     PHAssetCollectionSubtypeAlbumSyncedFaces     = 4,
///     PHAssetCollectionSubtypeAlbumSyncedAlbum     = 5,
///     PHAssetCollectionSubtypeAlbumImported        = 6,
///
///     // PHAssetCollectionTypeAlbum shared subtypes
///     PHAssetCollectionSubtypeAlbumMyPhotoStream   = 100,
///     PHAssetCollectionSubtypeAlbumCloudShared     = 101,
///
///     // PHAssetCollectionTypeSmartAlbum subtypes
///     PHAssetCollectionSubtypeSmartAlbumGeneric    = 200,
///     PHAssetCollectionSubtypeSmartAlbumPanoramas  = 201,
///     PHAssetCollectionSubtypeSmartAlbumVideos     = 202,
///     PHAssetCollectionSubtypeSmartAlbumFavorites  = 203,
///     PHAssetCollectionSubtypeSmartAlbumTimelapses = 204,
///     PHAssetCollectionSubtypeSmartAlbumAllHidden  = 205,
///     PHAssetCollectionSubtypeSmartAlbumRecentlyAdded = 206,
///     PHAssetCollectionSubtypeSmartAlbumBursts     = 207,
///     PHAssetCollectionSubtypeSmartAlbumSlomoVideos = 208,
///     PHAssetCollectionSubtypeSmartAlbumUserLibrary = 209,
///     PHAssetCollectionSubtypeSmartAlbumSelfPortraits API_AVAILABLE(ios(9)) = 210,
///     PHAssetCollectionSubtypeSmartAlbumScreenshots API_AVAILABLE(ios(9)) = 211,
///     PHAssetCollectionSubtypeSmartAlbumDepthEffect API_AVAILABLE(macos(10.13), ios(10.2), tvos(10.1)) = 212,
///     PHAssetCollectionSubtypeSmartAlbumLivePhotos API_AVAILABLE(macos(10.13), ios(10.3), tvos(10.2)) = 213,
///     PHAssetCollectionSubtypeSmartAlbumAnimated API_AVAILABLE(macos(10.15), ios(11), tvos(11)) = 214,
///     PHAssetCollectionSubtypeSmartAlbumLongExposures API_AVAILABLE(macos(10.15), ios(11), tvos(11)) = 215,
///     PHAssetCollectionSubtypeSmartAlbumUnableToUpload API_AVAILABLE(macos(10.15), ios(13), tvos(13)) = 216,
///     PHAssetCollectionSubtypeSmartAlbumRAW API_AVAILABLE(macos(12), ios(15), tvos(15)) = 217,
///     PHAssetCollectionSubtypeSmartAlbumCinematic API_AVAILABLE(macos(12), ios(15), tvos(15)) = 218,
///
///
///     // Used for fetching, if you don't care about the exact subtype
///     PHAssetCollectionSubtypeAny = NSIntegerMax
/// };
/// ```
enum PMDarwinAssetCollectionSubtype {
  // PHAssetCollectionTypeAlbum regular subtypes
  albumRegular,
  albumSyncedEvent,
  albumSyncedFaces,
  albumSyncedAlbum,
  albumImported,

  // PHAssetCollectionTypeAlbum shared subtypes
  albumMyPhotoStream,
  albumCloudShared,

  // PHAssetCollectionTypeSmartAlbum subtypes
  smartAlbumGeneric,
  smartAlbumPanoramas,
  smartAlbumVideos,
  smartAlbumFavorites,
  smartAlbumTimelapses,
  smartAlbumAllHidden,
  smartAlbumRecentlyAdded,
  smartAlbumBursts,
  smartAlbumSlomoVideos,
  smartAlbumUserLibrary,
  smartAlbumSelfPortraits,
  smartAlbumScreenshots,
  smartAlbumDepthEffect,
  smartAlbumLivePhotos,
  smartAlbumAnimated,
  smartAlbumLongExposures,
  smartAlbumUnableToUpload,
  smartAlbumRAW,
  smartAlbumCinematic,

  // Used for fetching, if you don't care about the exact subtype
  any,
}

extension PMDarwinAssetCollectionSubtypeExt on PMDarwinAssetCollectionSubtype {
  int get value {
    switch (this) {
      case PMDarwinAssetCollectionSubtype.albumRegular:
        return 2;
      case PMDarwinAssetCollectionSubtype.albumSyncedEvent:
        return 3;
      case PMDarwinAssetCollectionSubtype.albumSyncedFaces:
        return 4;
      case PMDarwinAssetCollectionSubtype.albumSyncedAlbum:
        return 5;
      case PMDarwinAssetCollectionSubtype.albumImported:
        return 6;
      case PMDarwinAssetCollectionSubtype.albumMyPhotoStream:
        return 100;
      case PMDarwinAssetCollectionSubtype.albumCloudShared:
        return 101;
      case PMDarwinAssetCollectionSubtype.smartAlbumGeneric:
        return 200;
      case PMDarwinAssetCollectionSubtype.smartAlbumPanoramas:
        return 201;
      case PMDarwinAssetCollectionSubtype.smartAlbumVideos:
        return 202;
      case PMDarwinAssetCollectionSubtype.smartAlbumFavorites:
        return 203;
      case PMDarwinAssetCollectionSubtype.smartAlbumTimelapses:
        return 204;
      case PMDarwinAssetCollectionSubtype.smartAlbumAllHidden:
        return 205;
      case PMDarwinAssetCollectionSubtype.smartAlbumRecentlyAdded:
        return 206;
      case PMDarwinAssetCollectionSubtype.smartAlbumBursts:
        return 207;
      case PMDarwinAssetCollectionSubtype.smartAlbumSlomoVideos:
        return 208;
      case PMDarwinAssetCollectionSubtype.smartAlbumUserLibrary:
        return 209;
      case PMDarwinAssetCollectionSubtype.smartAlbumSelfPortraits:
        return 210;
      case PMDarwinAssetCollectionSubtype.smartAlbumScreenshots:
        return 211;
      case PMDarwinAssetCollectionSubtype.smartAlbumDepthEffect:
        return 212;
      case PMDarwinAssetCollectionSubtype.smartAlbumLivePhotos:
        return 213;
      case PMDarwinAssetCollectionSubtype.smartAlbumAnimated:
        return 214;
      case PMDarwinAssetCollectionSubtype.smartAlbumLongExposures:
        return 215;
      case PMDarwinAssetCollectionSubtype.smartAlbumUnableToUpload:
        return 216;
      case PMDarwinAssetCollectionSubtype.smartAlbumRAW:
        return 217;
      case PMDarwinAssetCollectionSubtype.smartAlbumCinematic:
        return 218;
      case PMDarwinAssetCollectionSubtype.any:
        return (math.pow(2, 63) - 1).toInt();
    }
  }

  static Map<int, PMDarwinAssetCollectionSubtype?>? _valuesMap;

  static PMDarwinAssetCollectionSubtype? fromValue(int? value) {
    if (value == null) {
      return null;
    }
    if (_valuesMap == null) {
      _valuesMap = <int, PMDarwinAssetCollectionSubtype>{};
      for (final v in PMDarwinAssetCollectionSubtype.values) {
        _valuesMap![v.value] = v;
      }
    }

    return _valuesMap![value];
  }
}

/// File format UTIs
/// typedef NSString * AVFileType NS_EXTENSIBLE_STRING_ENUM;
enum PMDarwinAVFileType {
  /// @constant AVFileTypeQuickTimeMovie
  /// @abstract A UTI for the QuickTime movie file format.
  /// @discussion
  /// The value of this UTI is @"com.apple.quicktime-movie".
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeQuickTimeMovie API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  mov,

  /// @constant AVFileTypeMPEG4
  /// @abstract A UTI for the MPEG-4 file format.
  /// @discussion
  /// The value of this UTI is @"public.mpeg-4".
  /// Files are identified with the .mp4 extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeMPEG4 API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  mp4,

  /// @constant AVFileTypeAppleM4V
  /// @discussion
  /// The value of this UTI is @"com.apple.m4v-video".
  /// Files are identified with the .m4v extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeAppleM4V API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  m4v,

  /// @constant AVFileTypeAppleM4A
  /// @discussion
  /// The value of this UTI is @"com.apple.m4a-audio".
  /// Files are identified with the .m4a extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeAppleM4A API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  m4a,

  /// @constant AVFileType3GPP
  /// @abstract A UTI for the 3GPP file format.
  /// @discussion
  /// The value of this UTI is @"public.3gpp".
  /// Files are identified with the .3gp, .3gpp, and .sdv extensions.
  ///
  /// AVF_EXPORT AVFileType const AVFileType3GPP API_AVAILABLE(macos(10.11), ios(4.0), tvos(9.0), watchos(1.0));
  $3gp,

  /// @constant AVFileType3GPP2
  /// @abstract A UTI for the 3GPP file format.
  /// @discussion
  /// The value of this UTI is @"public.3gpp2".
  /// Files are identified with the .3g2, .3gp2 extensions.
  ///
  /// AVF_EXPORT AVFileType const AVFileType3GPP2 API_AVAILABLE(macos(10.11), ios(4.0), tvos(9.0), watchos(1.0));
  $3gp2,

  /// @constant AVFileTypeCoreAudioFormat
  /// @abstract A UTI for the Core Audio Format.
  /// @discussion
  /// The value of this UTI is @"com.apple.coreaudio-format".
  /// Files are identified with the .caf extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeCoreAudioFormat API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  caf,

  /// @constant AVFileTypeWAVE
  /// @abstract A UTI for the WAVE audio file format.
  /// @discussion
  /// The value of this UTI is @"com.microsoft.waveform-audio".
  /// Files are identified with the .wav extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeWAVE API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  wav,

  /// @constant AVFileTypeAIFF
  /// @abstract A UTI for the AIFF audio file format.
  /// @discussion
  /// The value of this UTI is @"public.aiff-audio".
  /// Files are identified with the .aiff extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeAIFF API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  aif,

  /// @constant AVFileTypeAIFC
  /// @abstract A UTI for the AIFC audio file format.
  /// @discussion
  /// The value of this UTI is @"public.aifc-audio".
  /// Files are identified with the .aifc extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeAIFC API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  aifc,

  /// @constant AVFileTypeAMR
  /// @abstract A UTI for the AMR audio file format.
  /// @discussion
  /// The value of this UTI is @"org.3gpp.adaptive-multi-rate-audio".
  /// Files are identified with the .amr extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeAMR API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  amr,

  /// @constant AVFileTypeMPEGLayer3
  /// @abstract A UTI for the MPEG Layer 3 audio file format.
  /// @discussion
  /// The value of this UTI is @"public.mp3".
  /// Files are identified with the .mp3 extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeMPEGLayer3 API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  mp3,

  /// @constant AVFileTypeSunAU
  /// @abstract A UTI for the Sun AU audio file format.
  /// @discussion
  /// The value of this UTI is @"public.au-audio".
  /// Files are identified with the .au extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeSunAU API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  au,

  /// @constant AVFileTypeAC3
  /// @abstract A UTI for the AC-3 audio file format.
  /// @discussion
  /// The value of this UTI is @"public.ac3-audio".
  /// Files are identified with the .ac3 extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeAC3 API_AVAILABLE(macos(10.7), ios(4.0), tvos(9.0), watchos(1.0));
  ac3,

  /// @constant AVFileTypeEnhancedAC3
  /// @abstract A UTI for the Enhanced AC-3 audio file format.
  /// @discussion
  /// The value of this UTI is @"public.enhanced-ac3".
  /// Files are identified with the .eac3 extension.
  ///
  /// AVF_EXPORT AVFileType const AVFileTypeEnhancedAC3 API_AVAILABLE(macos(10.11), ios(9.0), tvos(9.0), watchos(2.0));
  eac3,
}

extension PMDarwinAVFileTypeExt on PMDarwinAVFileType {
  int get value {
    switch (this) {
      case PMDarwinAVFileType.mov:
        return 1;
      case PMDarwinAVFileType.mp4:
        return 2;
      case PMDarwinAVFileType.m4v:
        return 3;
      case PMDarwinAVFileType.m4a:
        return 4;
      case PMDarwinAVFileType.$3gp:
        return 5;
      case PMDarwinAVFileType.$3gp2:
        return 6;
      case PMDarwinAVFileType.caf:
        return 7;
      case PMDarwinAVFileType.wav:
        return 8;
      case PMDarwinAVFileType.aif:
        return 9;
      case PMDarwinAVFileType.aifc:
        return 10;
      case PMDarwinAVFileType.amr:
        return 11;
      case PMDarwinAVFileType.mp3:
        return 12;
      case PMDarwinAVFileType.au:
        return 13;
      case PMDarwinAVFileType.ac3:
        return 14;
      case PMDarwinAVFileType.eac3:
        return 15;
    }
  }

  static Map<int, PMDarwinAVFileType?>? _valuesMap;

  static PMDarwinAVFileType? fromValue(int? value) {
    if (value == null) {
      return null;
    }
    if (_valuesMap == null) {
      _valuesMap = <int, PMDarwinAVFileType>{};
      for (final v in PMDarwinAVFileType.values) {
        _valuesMap![v.value] = v;
      }
    }
    return _valuesMap![value];
  }
}
