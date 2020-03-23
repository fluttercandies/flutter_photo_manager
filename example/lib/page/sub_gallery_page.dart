import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

class SubFolderPage extends StatefulWidget {
  final List<AssetPathEntity> pathList;

  const SubFolderPage({Key key, this.pathList}) : super(key: key);

  @override
  _SubFolderPageState createState() => _SubFolderPageState();
}

class _SubFolderPageState extends State<SubFolderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemBuilder: _buildItem,
        itemCount: widget.pathList.length,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = widget.pathList[index];
    return ListTile(
      title: Text(item.name),
      subtitle: Text("asset count: ${item.assetCount.toString()}"),
      onTap: () async {
        final subPath = await item.getSubPathList();
        if (subPath.length == 0) {
          showToast("no have sub path");
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) {
            return SubFolderPage(
              pathList: subPath,
            );
          }),
        );
      },
    );
  }
}
