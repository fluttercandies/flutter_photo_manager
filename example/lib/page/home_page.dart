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

  var hasAll = true;

  @override
  void initState() {
    super.initState();
    PhotoManager.addChangeCallback(onChange);
  }

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
          Row(
            children: <Widget>[
              _buildFecthDtPicker(),
              _buildDateToNow(),
            ],
            mainAxisSize: MainAxisSize.min,
          ),
          _buildHasAllCheck(),
          buildNotifyButton(),
          // buildAndroidQSwitch(),
        ],
      ),
    );
  }

  _scanGalleryList() async {
    var galleryList = await PhotoManager.getAssetPathList(
      fetchDateTime: this.dt,
      type: RequestType.values[type],
      hasAll: hasAll,
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
    return buildButton(
        "${dt.year}-${dt.month}-${dt.day} ${dt.hour}:${dt.minute}:${dt.second}",
        () async {
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

  Widget _buildHasAllCheck() {
    return CheckboxListTile(
      value: hasAll,
      onChanged: (value) {
        setState(() {
          hasAll = value;
        });
      },
      title: Text("hasAll"),
    );
  }

  Widget _buildDateToNow() {
    return buildButton("Date to now", () {
      setState(() {
        this.dt = DateTime.now();
      });
    });
  }

  bool notifying = false;

  Widget buildNotifyButton() {
    return buildButton("onChanged", () {
      notifying = !notifying;
      if (notifying) {
        PhotoManager.startChangeNotify();
      } else {
        PhotoManager.stopChangeNotify();
      }
    });
  }

  void onChange(call) {}

  // Widget buildAndroidQSwitch() {
  //   return CheckboxListTile(
  //     onChanged: (check) {
  //       PhotoManager.setAndroidQExperimental(check);
  //       setState(() {});
  //     },
  //     value: PhotoManager.androidQExperimental,
  //   );
  // }
}

Widget buildButton(String text, Function function) {
  return RaisedButton(
    child: Text(text),
    onPressed: function,
  );
}
