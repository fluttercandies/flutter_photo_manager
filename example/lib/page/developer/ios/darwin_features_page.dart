import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// Demonstrates the Darwin (iOS/macOS) only reads exposed through the
/// `AssetEntity.darwin` / `AssetPathEntity.darwin` namespaces:
///
///  * `asset.darwin.cloudIdentifier` and the batch
///    `PhotoManager.plugin.getCloudIdentifiers`
///  * `asset.darwin.hasAdjustments` + `asset.darwin.baseFile()`
///  * `path.darwin.getParentPathList()`
///
/// This page is only meaningful on iOS/macOS; the entry point in
/// `develop_index_page.dart` is already gated behind `Platform.isIOS ||
/// Platform.isMacOS`, and the page guards again at runtime so it degrades
/// gracefully if opened elsewhere.
class DarwinFeaturesPage extends StatefulWidget {
  const DarwinFeaturesPage({super.key});

  @override
  State<DarwinFeaturesPage> createState() => _DarwinFeaturesPageState();
}

class _DarwinFeaturesPageState extends State<DarwinFeaturesPage> {
  final List<String> _logs = <String>[];
  AssetEntity? _asset;
  bool _busy = false;

  bool get _supported => Platform.isIOS || Platform.isMacOS;

  void _log(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _logs.insert(0, message));
  }

  Future<bool> _ensurePermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      _log('❌ No photo access granted ($ps).');
      return false;
    }
    return true;
  }

  Future<AssetEntity?> _firstAsset() async {
    if (_asset != null) {
      return _asset;
    }
    final List<AssetPathEntity> paths =
        await PhotoManager.getAssetPathList(onlyAll: true);
    if (paths.isEmpty) {
      _log('❌ No album found.');
      return null;
    }
    final List<AssetEntity> assets =
        await paths.first.getAssetListPaged(page: 0, size: 1);
    if (assets.isEmpty) {
      _log('❌ No asset found.');
      return null;
    }
    _asset = assets.first;
    _log('📌 Using asset ${_asset!.id}');
    return _asset;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_supported) {
      _log('⚠️ Darwin-only APIs are unavailable on this platform.');
      return;
    }
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (await _ensurePermission()) {
        await action();
      }
    } catch (e) {
      _log('❌ $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cloudIdentifierSingle() async {
    final AssetEntity? asset = await _firstAsset();
    if (asset == null) {
      return;
    }
    final String? cloudId = await asset.darwin.cloudIdentifier;
    _log('☁️ cloudIdentifier: ${cloudId ?? '<null>'}');
  }

  Future<void> _cloudIdentifierBatch() async {
    final List<AssetPathEntity> paths =
        await PhotoManager.getAssetPathList(onlyAll: true);
    if (paths.isEmpty) {
      _log('❌ No album found.');
      return;
    }
    final List<AssetEntity> assets =
        await paths.first.getAssetListPaged(page: 0, size: 10);
    if (assets.isEmpty) {
      _log('❌ No asset found.');
      return;
    }
    final List<String> ids = assets.map((AssetEntity e) => e.id).toList();
    final Map<String, String?> mapping =
        await PhotoManager.plugin.getCloudIdentifiers(ids);
    _log(
      '☁️ Batch getCloudIdentifiers over ${ids.length} assets:\n'
      '${mapping.entries.map((e) => '  ${e.key} -> ${e.value ?? '<null>'}').join('\n')}',
    );
  }

  Future<void> _hasAdjustmentsAndBaseFile() async {
    final AssetEntity? asset = await _firstAsset();
    if (asset == null) {
      return;
    }
    final bool hasAdjustments = await asset.darwin.hasAdjustments;
    _log('✏️ hasAdjustments: $hasAdjustments');
    final File? base = await asset.darwin.baseFile();
    if (base == null) {
      _log('📄 baseFile: <null>');
      return;
    }
    final int length = await base.length();
    _log('📄 baseFile: ${base.path} ($length bytes)');
  }

  Future<void> _parentPaths() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );
    if (albums.isEmpty) {
      _log('❌ No album found.');
      return;
    }
    final StringBuffer buffer = StringBuffer('🗂 Parent folders per album:');
    // Probe up to 10 albums to keep the output readable.
    for (final AssetPathEntity album in albums.take(10)) {
      final List<AssetPathEntity> parents =
          await album.darwin.getParentPathList();
      final String parentNames = parents.isEmpty
          ? '(no parent)'
          : parents.map((AssetPathEntity p) => p.name).join(' / ');
      buffer.write('\n  ${album.name} -> $parentNames');
    }
    _log(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Darwin-only features')),
      body: !_supported
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'These APIs (cloudIdentifier / hasAdjustments / baseFile / '
                  'getParentPathList) are only available on iOS and macOS.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed:
                            _busy ? null : () => _run(_cloudIdentifierSingle),
                        child: const Text('cloudIdentifier (single)'),
                      ),
                      ElevatedButton(
                        onPressed:
                            _busy ? null : () => _run(_cloudIdentifierBatch),
                        child: const Text('getCloudIdentifiers (batch)'),
                      ),
                      ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(_hasAdjustmentsAndBaseFile),
                        child: const Text('hasAdjustments + baseFile'),
                      ),
                      ElevatedButton(
                        onPressed: _busy ? null : () => _run(_parentPaths),
                        child: const Text('getParentPathList'),
                      ),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _logs.clear();
                                  _asset = null;
                                }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
                if (_busy) const LinearProgressIndicator(),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (_, int index) => Text(
                      _logs[index],
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
