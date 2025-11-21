import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// Test page for moveAssetsToPath API (Android 11+ batch move with createWriteRequest)
class MoveAssetsBatchTestPage extends StatefulWidget {
  const MoveAssetsBatchTestPage({super.key});

  @override
  State<MoveAssetsBatchTestPage> createState() =>
      _MoveAssetsBatchTestPageState();
}

class _MoveAssetsBatchTestPageState extends State<MoveAssetsBatchTestPage> {
  List<AssetEntity> allAssets = [];
  Set<AssetEntity> selectedAssets = {};
  bool isLoading = false;
  String statusMessage = 'Ready to test';
  final TextEditingController _pathController =
      TextEditingController(text: 'Pictures/TestAlbum');

  @override
  void initState() {
    super.initState();
    _checkAndroid11();
    _loadAssets();
  }

  void _checkAndroid11() {
    if (Platform.isAndroid) {
      // You can check Android version if needed
      statusMessage = 'Android detected - Ready to test';
    } else {
      statusMessage = 'This feature is Android-only';
    }
  }

  Future<void> _loadAssets() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Loading assets...';
    });

    try {
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        setState(() {
          isLoading = false;
          statusMessage = '❌ Permission denied';
        });
        showToast('Permission denied. Please grant photo access.');
        return;
      }

      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (paths.isEmpty) {
        setState(() {
          isLoading = false;
          statusMessage = '❌ No albums found';
        });
        return;
      }

      // Get first 30 images for testing
      final List<AssetEntity> assets = await paths.first.getAssetListRange(
        start: 0,
        end: 30,
      );

      setState(() {
        allAssets = assets;
        isLoading = false;
        statusMessage =
            '✅ Loaded ${assets.length} assets. Select some to move.';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = '❌ Error: $e';
      });
      showToast('Error loading assets: $e');
    }
  }

  Future<void> _testMoveAssets() async {
    if (selectedAssets.isEmpty) {
      showToast('Please select at least one image');
      return;
    }

    final targetPath = _pathController.text.trim();
    if (targetPath.isEmpty) {
      showToast('Please enter a target path');
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage =
          'Moving ${selectedAssets.length} assets to $targetPath...';
    });

    try {
      final success = await PhotoManager.editor.android.moveAssetsToPath(
        entities: selectedAssets.toList(),
        targetPath: targetPath,
      );

      setState(() {
        isLoading = false;
        if (success) {
          statusMessage =
              '✅ Successfully moved ${selectedAssets.length} assets to $targetPath!';
          selectedAssets.clear();
        } else {
          statusMessage =
              '❌ Failed to move assets (user denied or error occurred)';
        }
      });

      showToast(
        success
            ? '✅ Move successful! Check "$targetPath" folder.'
            : '❌ Move failed or cancelled by user.',
        duration: const Duration(seconds: 3),
      );

      // Reload to see changes
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        _loadAssets();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = '❌ Error during move: $e';
      });
      showToast('Error: $e', duration: const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test: Move Assets (Batch)'),
        actions: [
          if (selectedAssets.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${selectedAssets.length} selected',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Android 11+ (API 30+) Batch Move Test',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  statusMessage,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // Target path input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Path (RELATIVE_PATH):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Pictures/MyAlbum',
                    helperText: 'MediaStore RELATIVE_PATH format',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Examples: Pictures/TestAlbum, DCIM/Camera, Download/',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Grid of images
          Expanded(
            child: isLoading && allAssets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : allAssets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              statusMessage,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAssets,
                              child: const Text('Reload Assets'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: allAssets.length,
                        itemBuilder: (context, index) {
                          final asset = allAssets[index];
                          final isSelected = selectedAssets.contains(asset);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedAssets.remove(asset);
                                } else {
                                  selectedAssets.add(asset);
                                }
                              });
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AssetEntityImage(
                                  asset,
                                  isOriginal: false,
                                  fit: BoxFit.cover,
                                ),
                                if (isSelected)
                                  Container(
                                    color: Colors.blue.withValues(alpha: 0.5),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: selectedAssets.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: isLoading ? null : _testMoveAssets,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.drive_file_move),
              label: Text(
                isLoading ? 'Moving...' : 'Move (${selectedAssets.length})',
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }
}
