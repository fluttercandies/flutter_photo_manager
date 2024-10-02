import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';
import '../util/log.dart';

class CopyToAnotherGalleryPage extends StatefulWidget {
  const CopyToAnotherGalleryPage({
    super.key,
    required this.assetEntity,
  });

  final AssetEntity assetEntity;

  @override
  State<CopyToAnotherGalleryPage> createState() =>
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
            child: AssetEntityImage(
              widget.assetEntity,
              thumbnailSize: const ThumbnailSize.square(500),
              loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
                if (progress == null) {
                  return child;
                }
                final double? value;
                if (progress.expectedTotalBytes != null) {
                  value = progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!;
                } else {
                  value = null;
                }
                return Center(
                  child: SizedBox.fromSize(
                    size: const Size.square(40),
                    child: CircularProgressIndicator(value: value),
                  ),
                );
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
    final AssetEntity result = await PhotoManager.editor.copyAssetToPath(
      asset: widget.assetEntity,
      pathEntity: targetGallery!,
    );

    Log.d('copy result = $result');
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
