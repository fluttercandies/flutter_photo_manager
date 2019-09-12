import 'package:flutter/material.dart';
import 'package:image_scanner_example/page/image_list_page.dart';
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
      appBar: AppBar(
        title: Text("Gallery list"),
      ),
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
      subtitle: Text("count : ${item.assetCount}"),
      trailing: Text("isAll : ${item.isAll}"),
      onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GalleryContentListPage(
                    path: item,
                  ),
            ),
          ),
      onLongPress: () async {
        await item.refreshPathProperties();
        setState(() {});
      },
    );
  }
}
