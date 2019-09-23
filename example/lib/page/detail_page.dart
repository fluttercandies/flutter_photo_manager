import 'dart:io';

import 'package:flutter/material.dart';
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
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.black,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.entity.type == AssetType.video) {
      return FutureBuilder(
        future: widget.entity.thumbData,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          return Image.memory(snapshot.data);
        },
      );
    }
    return Image.file(
      widget.file,
      filterQuality: FilterQuality.low,
    );
  }

  void _showInfo() {
    final entity = widget.entity;
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
            ],
          ),
        ),
      ),
    );
    showDialog(context: context, builder: (c) => w);
  }

  Widget buildInfoItem(String title, String info) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          child: Text(title),
          width: 88,
        ),
        Text(info),
      ],
    );
  }
}
