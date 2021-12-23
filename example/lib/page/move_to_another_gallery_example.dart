import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MoveToAnotherExample extends StatefulWidget {
  const MoveToAnotherExample({
    Key? key,
    required this.entity,
  }) : super(key: key);

  final AssetEntity entity;

  @override
  _MoveToAnotherExampleState createState() => _MoveToAnotherExampleState();
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
    return FutureBuilder<Uint8List?>(
      future: widget.entity.thumbDataWithSize(500, 500),
      builder: (_, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.data != null) {
          return Image.memory(snapshot.data!);
        }
        return const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(),
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
