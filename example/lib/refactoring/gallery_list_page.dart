import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryListPage extends StatefulWidget {
  final List<AssetPathEntity> galleryList;

  const GalleryListPage({Key key, this.galleryList}) : super(key: key);

  @override
  _GalleryListPageState createState() => _GalleryListPageState();
}

class _GalleryListPageState extends State<GalleryListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: ListView.builder(
          itemBuilder: _buildItem,
          itemCount: widget.galleryList.length,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = widget.galleryList[index];
    return ListTile(
      title: Text(item.name),
      subtitle: Text("count: ${item.assetCount}"),
    );
  }
}
