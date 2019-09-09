import 'package:flutter/material.dart';
import 'package:image_scanner_example/page/gallery_list_page.dart';
import 'package:photo_manager/photo_manager.dart';

class NewHomePage extends StatefulWidget {
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  Plugin plugin = Plugin();

  List<AssetPathEntity> list = [];

  int type = 0;

  DateTime dt = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("photo manager example"),
      ),
      body: Column(
        children: <Widget>[
          buildButton("Get all gallery list", _scanGalleryList),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("scan type"),
              Container(
                width: 10,
              ),
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
          _buildFecthDtPicker(),
        ],
      ),
    );
  }

  _scanGalleryList() async {
    var galleryList = await plugin.getAllGalleryList(
      type: type,
      dt: this.dt,
    );

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
    String typeText;
    if (i == 2) {
      typeText = "video";
    } else if (i == 1) {
      typeText = "image";
    } else {
      typeText = "all";
    }

    return DropdownMenuItem<int>(
      child: Text(typeText),
      value: i,
    );
  }

  Widget _buildFecthDtPicker() {
    return buildButton("$dt", () async {
      final pickDt = await showDatePicker(
        context: context,
        firstDate: DateTime(2018, 1, 1),
        initialDate: dt,
        lastDate: DateTime.now(),
      );
      if (pickDt != null) {
        setState(() {
          this.dt = pickDt;
        });
      }
    });
  }
}

Widget buildButton(String text, Function function) {
  return RaisedButton(
    child: Text(text),
    onPressed: function,
  );
}
