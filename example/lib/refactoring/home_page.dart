import 'package:flutter/material.dart';
import 'package:image_scanner_example/refactoring/gallery_list_page.dart';
import 'package:photo_manager/photo_manager.dart';

class NewHomePage extends StatefulWidget {
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  Plugin plugin = Plugin();

  List<AssetPathEntity> list = [];

  int type = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          buildButton("scan", _scanGalleryList),
          DropdownButton<int>(
            items: <DropdownMenuItem<int>>[
              _buildDropdownMenuItem(0),
              _buildDropdownMenuItem(1),
              _buildDropdownMenuItem(2),
            ],
            onChanged: (v) {
              this.type = v;
              setState(() {});
            },
            value: type,
          ),
        ],
      ),
    );
  }

  _scanGalleryList() async {
    var galleryList = await plugin.getAllGalleryList(type: type);

    print(galleryList.length);

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    final page = GalleryListPage(
      galleryList: galleryList,
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => page,
    ));
  }

  DropdownMenuItem<int> _buildDropdownMenuItem(int i) {
    return DropdownMenuItem<int>(
      child: Text(i.toString()),
      value: i,
    );
  }
}

Widget buildButton(String text, Function function) {
  return RaisedButton(
    child: Text(text),
    onPressed: function,
  );
}
