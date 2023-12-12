import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class MoveToAnotherExample extends StatefulWidget {
  const MoveToAnotherExample({
    super.key,
    required this.entity,
  });

  final AssetEntity entity;

  @override
  State<MoveToAnotherExample> createState() => _MoveToAnotherExampleState();
}

class _MoveToAnotherExampleState extends State<MoveToAnotherExample> {
  List<AssetPathEntity> targetPathList = <AssetPathEntity>[];
  AssetPathEntity? target;

  @override
  void initState() {
    super.initState();
    PhotoManager.getAssetPathList(hasAll: false).then(
      (List<AssetPathEntity> value) {
        targetPathList = value;
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Move to another gallery'),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: Container(
              color: Colors.grey,
              width: 300,
              height: 300,
              child: _buildPreview(),
            ),
          ),
          buildTarget(),
          buildMoveButton(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return AssetEntityImage(
      widget.entity,
      thumbnailSize: const ThumbnailSize.square(500),
      loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
        if (progress == null) {
          return child;
        }
        final double? value;
        if (progress.expectedTotalBytes != null) {
          value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
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
    );
  }

  Widget buildTarget() {
    return DropdownButton<AssetPathEntity>(
      items: targetPathList.map((AssetPathEntity v) => _buildItem(v)).toList(),
      value: target,
      onChanged: (AssetPathEntity? value) {
        target = value;
        setState(() {});
      },
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity v) {
    return DropdownMenuItem<AssetPathEntity>(
      value: v,
      child: Text(v.name),
    );
  }

  Widget buildMoveButton() {
    if (target == null) {
      return const SizedBox.shrink();
    }
    return ElevatedButton(
      onPressed: () {
        PhotoManager.editor.android.moveAssetToAnother(
          entity: widget.entity,
          target: target!,
        );
      },
      child: Text("Move to ' ${target!.name} '"),
    );
  }
}
