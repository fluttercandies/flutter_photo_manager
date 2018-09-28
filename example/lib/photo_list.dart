import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoList extends StatefulWidget {
  final List<ImageEntity> photos;

  PhotoList({this.photos});

  @override
  _PhotoListState createState() => _PhotoListState();
}

class _PhotoListState extends State<PhotoList> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
      ),
      itemBuilder: _buildItem,
      itemCount: widget.photos.length,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    var entity = widget.photos[index];
    return FutureBuilder<Uint8List>(
      future: entity.thumbData,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(
            snapshot.data,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
        return Center(
          child: Text('加载中'),
        );
      },
    );
  }
}
