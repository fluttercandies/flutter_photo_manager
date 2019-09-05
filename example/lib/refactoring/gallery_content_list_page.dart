import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryContentListPage extends StatefulWidget {
  final AssetPathEntity path;

  const GalleryContentListPage({Key key, this.path}) : super(key: key);
  @override
  _GalleryContentListPageState createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  List<AssetEntity> list = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemBuilder: _buildItem,
        itemCount: list.length,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = list[index];
    return AspectRatio(
      aspectRatio: 1,
      child: Image.file(File(item.id)),
    );
  }

  void initData() async {
    final list = await Plugin().getAssetWithGalleryIdPaged(path.id);
    this.list.addAll(list);
    setState(() {});
  }
}
