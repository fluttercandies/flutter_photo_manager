// #1118 diagnostic — measure whether `originFile` returns full-quality
// bytes for iCloud + "Optimize iPhone Storage" affected assets.
//
// Compares `AssetEntity.originFile.lengthSync()` against
// `AssetEntity.fileSize` (which surfaces `PHAssetResource.fileSize`, i.e.
// the byte size of the resource as stored in iCloud). If the returned
// file is significantly smaller than the resource's full size, we're
// still receiving the locally-downsampled proxy and the fix has not
// worked for that asset. Companion to the `[#1118]` logs emitted by the
// native side — grep those in the Xcode Console for the routing decision.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import 'issue_index_page.dart';

class Issue1118Page extends StatefulWidget {
  const Issue1118Page({super.key});

  @override
  State<Issue1118Page> createState() => _Issue1118PageState();
}

class _Issue1118PageState extends State<Issue1118Page>
    with IssueBase<Issue1118Page> {
  @override
  int get issueNumber => 1118;

  @override
  List<TargetPlatform>? get supportPlatforms => const [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ];

  static const int _scanLimit = 200;

  List<_Candidate> _candidates = [];
  bool _busy = false;

  Future<void> _scanCandidates() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final ps = await PhotoManager.requestPermissionExtend();
      if (!ps.hasAccess) {
        addLog('permission denied');
        return;
      }
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        )..addOrderOption(
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ),
      );
      if (paths.isEmpty) {
        addLog('no album found');
        return;
      }
      final album = paths.first;
      final total = await album.assetCountAsync;
      addLog('album=${album.name} total=$total, scanning latest $_scanLimit');
      final assets = await album.getAssetListRange(
        start: 0,
        end: total < _scanLimit ? total : _scanLimit,
      );
      final results = <_Candidate>[];
      for (var i = 0; i < assets.length; i++) {
        final a = assets[i];
        if (a.type != AssetType.image) {
          continue;
        }
        final size = await a.fileSize;
        final local = await a.isLocallyAvailable(isOrigin: true);
        results.add(_Candidate(a, size, local));
      }
      results.sort((x, y) => y.expectedSize.compareTo(x.expectedSize));
      setState(() => _candidates = results);
      final iCloudOnly = results.where((c) => !c.locallyAvailable).length;
      final localOnly = results.length - iCloudOnly;
      addLog(
        'scanned ${results.length} images '
        '— iCloud-only=$iCloudOnly local=$localOnly '
        '(sorted by expected size desc)',
      );
    } catch (e, s) {
      addLog('scan failed: $e\n$s');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _diagOne(_Candidate c) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      addLog('DIAG ${c.asset.id} — expected=${_fmt(c.expectedSize)} '
          'local=${c.locallyAvailable}');
      final sw = Stopwatch()..start();
      File? file;
      Object? err;
      try {
        file = await c.asset.originFile;
      } catch (e) {
        err = e;
      }
      sw.stop();
      if (err != null || file == null) {
        addLog(
          '  → FAILED in ${sw.elapsedMilliseconds}ms: ${err ?? "null file"}',
        );
        return;
      }
      final actual = file.lengthSync();
      final ratio = c.expectedSize == 0 ? 0.0 : actual / c.expectedSize;
      String verdict;
      if (c.expectedSize == 0) {
        verdict = '? (fileSize unknown)';
      } else if (ratio >= 0.99) {
        verdict = '✓ FULL';
      } else if (ratio < 0.5) {
        verdict = '✗ PROXY(#1118!)';
      } else {
        verdict = '~ MISMATCH (ratio=${ratio.toStringAsFixed(2)})';
      }
      addLog(
        '  → actual=${_fmt(actual)} in ${sw.elapsedMilliseconds}ms $verdict',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _diagBatch({bool iCloudOnly = false}) async {
    if (_busy) {
      return;
    }
    final targets = iCloudOnly
        ? _candidates.where((c) => !c.locallyAvailable).toList()
        : _candidates;
    if (targets.isEmpty) {
      showToast(iCloudOnly ? 'no iCloud-only candidates' : 'scan first');
      return;
    }
    addLog('--- batch diag over ${targets.length} candidates ---');
    for (final c in targets.take(10)) {
      await _diagOne(c);
    }
    addLog('--- batch diag done ---');
  }

  Future<void> _clearCache() async {
    await PhotoManager.clearFileCache();
    addLog('file cache cleared');
  }

  static String _fmt(int bytes) {
    if (bytes >= 1 << 20) {
      return '${(bytes / (1 << 20)).toStringAsFixed(2)}MB';
    }
    if (bytes >= 1 << 10) {
      return '${(bytes / (1 << 10)).toStringAsFixed(1)}KB';
    }
    return '${bytes}B';
  }

  Widget _buildCandidateList() {
    if (_candidates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Tap "Scan candidates" to list assets.'),
      );
    }
    return Expanded(
      child: ListView.separated(
        itemCount: _candidates.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = _candidates[i];
          return ListTile(
            dense: true,
            title: Text(
              '${c.asset.id.split('/').first}  '
              '${c.asset.width}×${c.asset.height}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            subtitle: Text(
              'expected=${_fmt(c.expectedSize)}  '
              'local=${c.locallyAvailable ? "yes" : "NO (iCloud-only)"}  '
              'type=${c.asset.mimeType ?? "?"}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow, size: 20),
              tooltip: 'Diag this asset',
              onPressed: _busy ? null : () => _diagOne(c),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'On-device diagnostic for #1118.\n'
              '1. Scan candidates (reads fileSize + isLocallyAvailable).\n'
              '2. Pick an iCloud-only asset (large expected size) '
              'and tap ▶ or "Diag batch".\n'
              '3. Compare actual vs expected in the log below.\n'
              '4. Xcode Console → grep [#1118] for the native routing '
              'decision + delivered byte count.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                buildButton('Scan candidates', _scanCandidates),
                buildButton(
                  'Diag batch (all top-10)',
                  () => _diagBatch(),
                ),
                buildButton(
                  'Diag batch (iCloud-only top-10)',
                  () => _diagBatch(iCloudOnly: true),
                ),
                buildButton('Clear file cache', _clearCache),
              ],
            ),
            const SizedBox(height: 8),
            _buildCandidateList(),
            const Divider(),
            buildLogWidget(),
          ],
        ),
      ),
    );
  }
}

class _Candidate {
  _Candidate(this.asset, this.expectedSize, this.locallyAvailable);

  final AssetEntity asset;
  final int expectedSize;
  final bool locallyAvailable;
}
