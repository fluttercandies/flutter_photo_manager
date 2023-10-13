// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data' as typed_data;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../types/entity.dart';
import '../types/thumbnail.dart';
import 'constants.dart';
import 'enums.dart';

final _providerLocks = <AssetEntityImageProvider, Completer<ui.Codec>>{};

/// The [ImageProvider] that handles [AssetEntity].
///
/// Only support [AssetType.image] and [AssetType.video],
/// others will throw errors during the resolving.
///
/// If [isOriginal] is true:
///   * Fetch [AssetEntity.thumbnailData] for [AssetType.video].
///   * Fetch [AssetEntity.file] and convert to bytes for HEIF(HEIC) images.
///   * Fetch [AssetEntity.originBytes] for images.
/// Else, fetch [AssetEntity.thumbnailDataWithOption] with the given
/// [thumbnailSize] and the [thumbnailFormat].
///
/// {@template remove_in_3_0}
/// ***
/// Because the Flutter version changes, there will be compatibility issues.
/// This class is expected to be removed in 3.0 and become a separate package.
/// ***
/// {@endtemplate}
@immutable
class AssetEntityImageProvider extends ImageProvider<AssetEntityImageProvider> {
  const AssetEntityImageProvider(
    this.entity, {
    this.isOriginal = true,
    this.thumbnailSize = PMConstants.vDefaultGridThumbnailSize,
    this.thumbnailFormat = ThumbnailFormat.jpeg,
  }) : assert(
          isOriginal || thumbnailSize != null,
          "thumbSize must not be null when it's not original",
        );

  /// {@macro photo_manager.AssetEntity}
  final AssetEntity entity;

  /// Choose if original data or thumb data should be loaded.
  /// 选择载入原数据还是缩略图数据。
  final bool isOriginal;

  /// Size for thumb data.
  /// 缩略图的大小。
  final ThumbnailSize? thumbnailSize;

  /// {@macro photo_manager.ThumbnailFormat}
  final ThumbnailFormat thumbnailFormat;

  /// File type for the image asset, use it for some special type detection.
  /// 图片资源的类型，用于某些特殊类型的判断。
  ImageFileType get imageFileType => _getType();

  @override
  ImageStreamCompleter load(
    AssetEntityImageProvider key,
    DecoderCallback decode, // ignore: deprecated_member_use
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: '${key.entity.runtimeType}-'
          '${key.entity.id}-'
          '${isOriginal ? 'origin-' : ''}'
          '${isOriginal ? '' : '$thumbnailFormat'}',
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<AssetEntityImageProvider>('Image key', key),
        ];
      },
    );
  }

  @override
  Future<AssetEntityImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetEntityImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(
    AssetEntityImageProvider key,
    DecoderCallback decode, // ignore: deprecated_member_use
  ) {
    if (_providerLocks.containsKey(key)) {
      return _providerLocks[key]!.future;
    }
    final lock = Completer<ui.Codec>();
    _providerLocks[key] = lock;
    Future(() async {
      try {
        assert(key == this);
        if (key.entity.type == AssetType.audio ||
            key.entity.type == AssetType.other) {
          throw UnsupportedError(
            'Image data for the ${key.entity.type} is not supported.',
          );
        }

        // Define the image type.
        final ImageFileType type;
        if (key.imageFileType == ImageFileType.other) {
          // Assume the title is invalid here, try again with the async getter.
          type = _getType(await key.entity.titleAsync);
        } else {
          type = key.imageFileType;
        }

        typed_data.Uint8List? data;
        if (isOriginal) {
          if (key.entity.type == AssetType.video) {
            data = await key.entity.thumbnailData;
          } else if (type == ImageFileType.heic) {
            data = await (await key.entity.file)?.readAsBytes();
          } else {
            data = await key.entity.originBytes;
          }
        } else {
          data = await key.entity.thumbnailDataWithOption(
            _thumbOption(thumbnailSize!),
          );
        }
        if (data == null) {
          throw StateError('The data of the entity is null: $entity');
        }
        return decode(data);
      } catch (e, s) {
        if (kDebugMode) {
          FlutterError.presentError(
            FlutterErrorDetails(
              exception: e,
              stack: s,
              library: PMConstants.libraryName,
            ),
          );
        }
        // Depending on where the exception was thrown, the image cache may not
        // have had a chance to track the key in the cache at all.
        // Schedule a microtask to give the cache a chance to add the key.
        Future<void>.microtask(() => _evictCache(key));
        rethrow;
      }
    }).then((codec) {
      lock.complete(codec);
    }).catchError((e, s) {
      lock.completeError(e, s);
    }).whenComplete(() {
      _providerLocks.remove(key);
    });
    return lock.future;
  }

  ThumbnailOption _thumbOption(ThumbnailSize size) {
    if (Platform.isIOS || Platform.isMacOS) {
      return ThumbnailOption.ios(size: size, format: thumbnailFormat);
    }
    return ThumbnailOption(size: size, format: thumbnailFormat);
  }

  /// Get image type by reading the file extension.
  /// 从图片后缀判断图片类型
  ///
  /// ⚠ Not all the system version support read file name from the entity,
  /// so this method might not work sometime.
  /// 并非所有的系统版本都支持读取文件名，所以该方法有时无法返回正确的类型。
  ImageFileType _getType([String? filename]) {
    ImageFileType? type;
    final String? extension = filename?.split('.').last ??
        entity.mimeType?.split('/').last ??
        entity.title?.split('.').last;
    if (extension != null) {
      switch (extension.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          type = ImageFileType.jpg;
          break;
        case 'png':
          type = ImageFileType.png;
          break;
        case 'gif':
          type = ImageFileType.gif;
          break;
        case 'tiff':
          type = ImageFileType.tiff;
          break;
        case 'heic':
          type = ImageFileType.heic;
          break;
        default:
          type = ImageFileType.other;
          break;
      }
    }
    return type ?? ImageFileType.other;
  }

  static void _evictCache(AssetEntityImageProvider key) {
    // ignore: unnecessary_cast
    ((PaintingBinding.instance as PaintingBinding).imageCache as ImageCache)
        .evict(key);
  }

  @override
  bool operator ==(Object other) {
    if (other is! AssetEntityImageProvider) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return entity == other.entity &&
        thumbnailSize == other.thumbnailSize &&
        thumbnailFormat == other.thumbnailFormat &&
        isOriginal == other.isOriginal;
  }

  @override
  int get hashCode =>
      entity.hashCode ^
      isOriginal.hashCode ^
      thumbnailSize.hashCode ^
      thumbnailFormat.hashCode;
}

/// A widget that displays an [AssetEntity] image.
///
/// The widget uses [AssetEntityImageProvider] internally to resolve assets.
///
/// {@macro remove_in_3_0}
class AssetEntityImage extends Image {
  AssetEntityImage(
    this.entity, {
    this.isOriginal = true,
    this.thumbnailSize = PMConstants.vDefaultGridThumbnailSize,
    this.thumbnailFormat = ThumbnailFormat.jpeg,
    Key? key,
    ImageFrameBuilder? frameBuilder,
    ImageLoadingBuilder? loadingBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
  }) : super(
          key: key,
          image: AssetEntityImageProvider(
            entity,
            isOriginal: isOriginal,
            thumbnailSize: thumbnailSize,
            thumbnailFormat: thumbnailFormat,
          ),
          frameBuilder: frameBuilder,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          semanticLabel: semanticLabel,
          excludeFromSemantics: excludeFromSemantics,
          width: width,
          height: height,
          color: color,
          opacity: opacity,
          colorBlendMode: colorBlendMode,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          centerSlice: centerSlice,
          matchTextDirection: matchTextDirection,
          gaplessPlayback: gaplessPlayback,
          isAntiAlias: isAntiAlias,
          filterQuality: filterQuality,
        );

  final AssetEntity entity;
  final bool isOriginal;
  final ThumbnailSize? thumbnailSize;
  final ThumbnailFormat thumbnailFormat;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AssetEntity>('entity', entity));
    properties.add(DiagnosticsProperty<bool>('isOriginal', isOriginal));
    properties.add(
      DiagnosticsProperty<ThumbnailSize>('thumbnailSize', thumbnailSize),
    );
    properties.add(
      DiagnosticsProperty<ThumbnailFormat>('thumbnailFormat', thumbnailFormat),
    );
  }
}
