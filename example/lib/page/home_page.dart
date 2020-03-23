import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/page/gallery_list_page.dart';
import 'package:image_scanner_example/widget/change_notifier_builder.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'filter_option_page.dart';

class NewHomePage extends StatefulWidget {
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  PhotoProvider get provider => Provider.of<PhotoProvider>(context);

  @override
  void initState() {
    super.initState();
    PhotoManager.addChangeCallback(onChange);
    PhotoManager.setLog(true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      value: provider,
      builder: (_, __) => Scaffold(
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
              ],
            ),
            _buildTypeChecks(provider),
            _buildHasAllCheck(),
            _buildOnlyAllCheck(),
            _buildPngCheck(),
            _buildNotifyCheck(),
            _buildFilterOption(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChecks(PhotoProvider provider) {
    final currentType = provider.type;
    Widget buildType(RequestType type) {
      String typeText;
      if (type.containsImage()) {
        typeText = "image";
      } else if (type.containsVideo()) {
        typeText = "video";
      } else if (type.containsAudio()) {
        typeText = "audio";
      } else {
        typeText = "";
      }

      return Expanded(
        child: CheckboxListTile(
          title: Text(typeText),
          value: currentType.containsType(type),
          onChanged: (bool value) {
            if (value) {
              provider.changeType(currentType + type);
            } else {
              provider.changeType(currentType - type);
            }
          },
        ),
      );
    }

    return Container(
      height: 50,
      child: Row(
        children: <Widget>[
          buildType(RequestType.image),
          buildType(RequestType.video),
          buildType(RequestType.audio),
        ],
      ),
    );
  }

  _scanGalleryList() async {
    await provider.refreshGalleryList();

    final page = GalleryListPage();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => page,
    ));
  }

  Widget _buildHasAllCheck() {
    return CheckboxListTile(
      value: provider.hasAll,
      onChanged: (value) {
        provider.changeHasAll(value);
      },
      title: Text("hasAll"),
    );
  }

  Widget _buildPngCheck() {
    return CheckboxListTile(
      value: provider.thumbFormat == ThumbFormat.png,
      onChanged: (value) {
        provider.changeThumbFormat();
      },
      title: Text("thumb png"),
    );
  }

  Widget _buildOnlyAllCheck() {
    return CheckboxListTile(
      value: provider.onlyAll,
      onChanged: (value) {
        provider.changeOnlyAll(value);
      },
      title: Text("onlyAll"),
    );
  }

  Widget _buildNotifyCheck() {
    return CheckboxListTile(
        value: provider.notifying,
        title: Text("onChanged"),
        onChanged: (value) {
          provider.notifying = value;

          if (value) {
            PhotoManager.startChangeNotify();
          } else {
            PhotoManager.stopChangeNotify();
          }
        });
  }

  void onChange(call) {}

  Widget _buildFilterOption(PhotoProvider provider) {
    return RaisedButton(
      child: Text("Change filter options."),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return FilterOptionPage();
            },
          ),
        );
      },
    );
  }
}

Widget buildButton(String text, Function function) {
  return RaisedButton(
    child: Text(text),
    onPressed: function,
  );
}
