import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'model/photo_provider.dart';
import 'page/index_page.dart';

final PhotoProvider provider = PhotoProvider();

void main() => runApp(const _SimpleExampleApp());

class _SimpleExampleApp extends StatelessWidget {
  const _SimpleExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: ChangeNotifierProvider<PhotoProvider>.value(
        value: provider, // This is for the advanced usages.
        child: const MaterialApp(home: _SimpleExamplePage()),
      ),
    );
  }
}

class _SimpleExamplePage extends StatefulWidget {
  const _SimpleExamplePage({Key? key}) : super(key: key);

  @override
  _SimpleExamplePageState createState() => _SimpleExamplePageState();
}

class _SimpleExamplePageState extends State<_SimpleExamplePage> {
  /// Customize your own filter options.
  final FilterOptionGroup _filterOptionGroup = FilterOptionGroup(
    imageOption: const FilterOption(
      sizeConstraint: SizeConstraint(ignoreSize: true),
    ),
  );
  List<AssetPathEntity>? _paths;
  List<AssetEntity>? _entities;

  Future<void> _requestAssets() async {
    // First, request permissions.
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();
    if (!mounted) {
      return;
    }
    // Further requests can be only procceed with authorized or limited.
    if (_ps != PermissionState.authorized && _ps != PermissionState.limited) {}
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      filterOption: _filterOptionGroup,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _paths = paths;
    });
    if (_paths!.isEmpty) {
      return;
    }
    final List<AssetEntity> entities = await _paths!.first.getAssetListPaged(
      page: 0,
      size: 50,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _entities = entities;
    });
  }

  Widget _buildBody(BuildContext context) {
    if (_paths == null) {
      return const Center(child: Text('Request paths first.'));
    }
    if (_paths!.isEmpty) {
      return const Center(child: Text('No paths found on this device.'));
    }
    if (_entities != null) {
      if (_entities!.isEmpty) {
        return const Center(child: Text('No assets found on this device.'));
      }
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: _entities!.length,
        itemBuilder: (BuildContext context, int index) {
          final AssetEntity entity = _entities![index];
          return Image(
            image: AssetEntityImageProvider(entity, isOriginal: false),
            fit: BoxFit.cover,
          );
        },
      );
    }
    return const Center(child: CircularProgressIndicator.adaptive());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('photo_manager')),
      body: Column(
        children: <Widget>[
          const Text(
            'This page will only obtain the first page of assets '
            'under the primary album (a.k.a. Recent). '
            'If you want more filtering assets, '
            'head over to "Advanced usages".',
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
      persistentFooterButtons: <TextButton>[
        TextButton(
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const IndexPage()),
            );
          },
          child: const Text('Advanced usages'),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _requestAssets,
        child: const Icon(Icons.developer_board),
      ),
    );
  }
}
