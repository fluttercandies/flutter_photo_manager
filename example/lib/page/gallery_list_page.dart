import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/page/image_list_page.dart';
import 'package:image_scanner_example/widget/dialog/list_dialog.dart';
import 'package:provider/provider.dart';

import 'sub_gallery_page.dart';

class GalleryListPage extends StatefulWidget {
  const GalleryListPage({Key key}) : super(key: key);

  @override
  _GalleryListPageState createState() => _GalleryListPageState();
}

class _GalleryListPageState extends State<GalleryListPage> {
  PhotoProvider get provider => Provider.of<PhotoProvider>(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gallery list"),
      ),
      body: Container(
        child: Scrollbar(
          child: ListView.builder(
            itemBuilder: _buildItem,
            itemCount: provider.list.length,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = provider.list[index];
    return GestureDetector(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text("count : ${item.assetCount}"),
        trailing: Text("isAll : ${item.isAll}"),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GalleryContentListPage(
            path: item,
          ),
        ),
      ),
      onLongPress: () async {
        showDialog(
          context: context,
          builder: (_) {
            return ListDialog(
              children: [
                RaisedButton(
                  child: Text("refrsh properties"),
                  onPressed: () async {
                    await item.refreshPathProperties();
                    setState(() {});
                  },
                ),
                RaisedButton(
                  child: Text("get sub path"),
                  onPressed: () async {
                    final subPath = await item.getSubPathList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) {
                        return SubFolderPage(
                          pathList: subPath,
                        );
                      }),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
      onDoubleTap: () async {
        final list =
            await item.getAssetListRange(start: 0, end: item.assetCount);
        for (var i = 0; i < list.length; i++) {
          final asset = list[i];
          debugPrint("$i : ${asset.id}");
        }
      },
    );
  }
}
