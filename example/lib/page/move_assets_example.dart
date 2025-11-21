// Example: How to use moveAssetsToPath for batch moving assets
//
// This example demonstrates how to move multiple images to a different album
// on Android 11+ (API 30+) with a single user permission dialog.

import 'package:photo_manager/photo_manager.dart';

/// Move multiple assets to a target album with user permission.
///
/// This method is useful when you want to move 20+ images at once,
/// as it shows only one system permission dialog instead of multiple.
Future<void> moveAssetsToAlbumExample() async {
  // Step 1: Request permission
  final PermissionState permission =
      await PhotoManager.requestPermissionExtend();
  if (!permission.isAuth) {
    print('Permission denied');
    return;
  }

  // Step 2: Get the assets you want to move
  // For example, get 20 recent images
  final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
    type: RequestType.image,
  );

  if (paths.isEmpty) {
    print('No albums found');
    return;
  }

  final AssetPathEntity recentAlbum = paths.first;
  final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
    start: 0,
    end: 20,
  );

  if (assets.isEmpty) {
    print('No assets found');
    return;
  }

  // Step 3: Define the target path
  // IMPORTANT: Use RELATIVE_PATH format, not album ID
  // Examples:
  //   - "Pictures/MyAlbum"
  //   - "DCIM/Camera"
  //   - "Pictures/Vacation2024"
  const String targetPath = 'Pictures/MyAlbum';

  // Step 4: Move assets with permission
  print('Moving ${assets.length} assets to $targetPath...');

  final bool success = await PhotoManager.editor.android.moveAssetsToPath(
    entities: assets,
    targetPath: targetPath,
  );

  if (success) {
    print('✅ Successfully moved ${assets.length} assets!');
    print('User approved the permission and files were moved.');
  } else {
    print('❌ Failed to move assets.');
    print('User may have denied permission or an error occurred.');
  }
}

/// Example: Move specific assets (e.g., assets from a specific date)
Future<void> moveSpecificAssetsExample() async {
  final PermissionState permission =
      await PhotoManager.requestPermissionExtend();
  if (!permission.isAuth) {
    return;
  }

  // Get all images
  final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
    type: RequestType.image,
  );

  if (paths.isEmpty) {
    return;
  }

  final AssetPathEntity allPhotos = paths.first;
  final List<AssetEntity> allAssets = await allPhotos.getAssetListRange(
    start: 0,
    end: 100,
  );

  // Filter assets (e.g., from a specific date)
  final DateTime targetDate = DateTime(2024, 11, 1);
  final List<AssetEntity> filteredAssets = allAssets.where((asset) {
    final DateTime assetDate = asset.createDateTime;
    return assetDate.year == targetDate.year &&
        assetDate.month == targetDate.month &&
        assetDate.day == targetDate.day;
  }).toList();

  if (filteredAssets.isEmpty) {
    print('No assets found for the specified date');
    return;
  }

  print(
    'Found ${filteredAssets.length} assets from ${targetDate.toString().split(' ')[0]}',
  );

  // Move to a date-specific album
  const String targetPath = 'Pictures/2024-11-01';
  final bool success = await PhotoManager.editor.android.moveAssetsToPath(
    entities: filteredAssets,
    targetPath: targetPath,
  );

  print(success ? '✅ Moved successfully' : '❌ Move failed');
}

/// Important Notes:
///
/// 1. Android Version Requirements:
///    - Android 11+ (API 30+): Use moveAssetsToPath
///    - Android 10 and below: Use moveAssetToAnother
///
/// 2. Target Path Format:
///    - Use RELATIVE_PATH format: "Pictures/AlbumName"
///    - NOT album ID or absolute path
///    - Common prefixes: "Pictures/", "DCIM/", "Download/"
///
/// 3. User Permission:
///    - Shows a single system dialog for all assets
///    - User can approve or deny the entire batch
///    - Returns false if user denies permission
///
/// 4. Error Handling:
///    - Returns false on any error (permission denied, invalid path, etc.)
///    - Check Android version before calling (API 30+)
///    - Verify target path format is correct
///
/// 5. Performance:
///    - Batch operations are efficient (single permission dialog)
///    - Can move 20+ images with one user interaction
///    - Much better UX than individual move operations
