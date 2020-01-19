import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_scanner_example/widget/video_widget.dart';
import 'package:photo_manager/photo_manager.dart';

class DetailPage extends StatefulWidget {
  final File file;
  final AssetEntity entity;

  const DetailPage({Key key, this.file, this.entity}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Asset file"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Center(
        child: Container(
          color: Colors.black,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.entity.type == AssetType.video) {
      return buildVideo();
    } else {
      return buildImage();
    }
  }

  Widget buildImage() {
    return Image.file(
      widget.file,
      filterQuality: FilterQuality.low,
    );
  }

  Widget buildVideo() {
    return VideoWidget(
      file: widget.file,
    );
  }

  void _showInfo() async {
    final entity = widget.entity;

    final latlng = await entity.latlngAsync();

    final lat = entity.latitude == 0 ? latlng.latitude : latlng.latitude;
    final lng = entity.longitude == 0 ? latlng.longitude : latlng.longitude;

    Widget w = Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(15),
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildInfoItem("create", entity.createDateTime.toString()),
              buildInfoItem("modified", entity.modifiedDateTime.toString()),
              buildInfoItem("size", entity.size.toString()),
              buildInfoItem("duration", entity.videoDuration.toString()),
              buildInfoItemAsync("title", entity.titleAsync),
              buildInfoItem("lat", lat?.toString() ?? "null"),
              buildInfoItem("lng", lng?.toString() ?? "null"),
            ],
          ),
        ),
      ),
    );
    showDialog(context: context, builder: (c) => w);
  }

  Widget buildInfoItem(String title, String info) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              title.padLeft(10, " "),
              textAlign: TextAlign.start,
            ),
            width: 88,
          ),
          Expanded(
            child: Text(info.padLeft(40, " ")),
          ),
        ],
      ),
    );
  }

  Widget buildInfoItemAsync(String title, Future<String> info) {
    return FutureBuilder(
      future: info,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return buildInfoItem(title, "");
        }
        return buildInfoItem(title, snapshot.data);
      },
    );
  }
}
