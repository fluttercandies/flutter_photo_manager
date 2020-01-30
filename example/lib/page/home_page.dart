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
                DropdownButton<int>(
                  items: <DropdownMenuItem<int>>[
                    _buildDropdownMenuItem(0),
                    _buildDropdownMenuItem(1),
                    _buildDropdownMenuItem(2),
                  ],
                  onChanged: (v) {
                    provider.changeType(v);
                  },
                  value: provider.type,
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
            _buildNotifyCheck(),
            _buildFilterOption(provider),
          ],
        ),
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
    final dt = provider.dt;
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
        provider.changeDate(pickDt);
      }
    });
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

  Widget _buildDateToNow() {
    return buildButton("Date to now", () {
      provider.changeDateToNow();
    });
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
