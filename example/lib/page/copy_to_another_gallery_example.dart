import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';

class CopyToAnotherGalleryPage extends StatefulWidget {
  const CopyToAnotherGalleryPage({
    Key? key,
    required this.assetEntity,
  }) : super(key: key);

  final AssetEntity assetEntity;

  @override
  _CopyToAnotherGalleryPageState createState() =>
      _CopyToAnotherGalleryPageState();
}

class _CopyToAnotherGalleryPageState extends State<CopyToAnotherGalleryPage> {
  AssetPathEntity? targetGallery;

  @override
  Widget build(BuildContext context) {
    final PhotoProvider provider =
        Provider.of<PhotoProvider>(context, listen: false);
    final List<AssetPathEntity> list = provider.list;
    return Scaffold(
      appBar: AppBar(
        title: const Text('move to another'),
      ),
      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: FutureBuilder<Uint8List?>(
              future: widget.assetEntity.thumbDataWithSize(500, 500),
              builder:
                  (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(snapshot.data!);
                }
                return const Text('loading');
              },
            ),
          ),
          DropdownButton<AssetPathEntity>(
            onChanged: (AssetPathEntity? value) {
              targetGallery = value;
              setState(() {});
            },
            value: targetGallery,
            hint: const Text('Select target gallery'),
            items: list
                .map<DropdownMenuItem<AssetPathEntity>>((AssetPathEntity item) {
              return _buildItem(item);
            }).toList(),
          ),
          _buildCopyButton(),
        ],
      ),
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity item) {
    return DropdownMenuItem<AssetPathEntity>(
      value: item,
      child: Text(item.name),
    );
  }

  Future<void> _copy() async {
    if (targetGallery == null) {
      return;
    }
    final AssetEntity? result = await PhotoManager.editor.copyAssetToPath(
      asset: widget.assetEntity,
      pathEntity: targetGallery!,
    );

    print('copy result = $result');
  }

  Widget _buildCopyButton() {
    return ElevatedButton(
      onPressed: _copy,
      child: Text(
        targetGallery == null
            ? 'Please select gallery'
            : 'copy to ${targetGallery!.name}',
      ),
    );
  }
}
