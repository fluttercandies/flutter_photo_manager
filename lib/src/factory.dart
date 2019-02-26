part of '../photo_manager.dart';

/// create AssetEntity with id
///
/// result is nullable
Future<AssetEntity> createAssetEntityWithId(String id) {
  return PhotoManager._createAssetEntityWithId(id);
}
