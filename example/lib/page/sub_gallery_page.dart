import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widget/gallery_item_widget.dart';

class SubFolderPage extends StatefulWidget {
  const SubFolderPage({
    super.key,
    required this.pathList,
    required this.title,
  });

  final List<AssetPathEntity> pathList;
  final String title;

  @override
  State<SubFolderPage> createState() => _SubFolderPageState();
}

class _SubFolderPageState extends State<SubFolderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemBuilder: _buildItem,
        itemCount: widget.pathList.length,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final AssetPathEntity item = widget.pathList[index];
    return GalleryItemWidget(
      path: item,
      setState: setState,
    );
  }
}
