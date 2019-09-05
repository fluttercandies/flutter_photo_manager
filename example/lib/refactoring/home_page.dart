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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          buildButton("scan", _scanGalleryList),
        ],
      ),
    );
  }

  _scanGalleryList() async {
    var galleryList = await plugin.getAllGalleryList();

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
}

Widget buildButton(String text, Function function) {
  return RaisedButton(
    child: Text(text),
    onPressed: function,
  );
}
