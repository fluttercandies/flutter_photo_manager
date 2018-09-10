import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_scanner/image_scanner.dart';

class PhotoPage extends StatefulWidget {
  final String name;
  final List<ImageEntity> photos;

  const PhotoPage({Key key, this.name, this.photos}) : super(key: key);

  @override
  _PhotoPageState createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        itemBuilder: _buildItem,
        itemCount: widget.photos.length,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    var data = widget.photos[index];
    // SystemChannels
    return FutureBuilder<String>(
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        print("snapshot.connectionState state = ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.done) {
          var data = snapshot.data;
          print(data);
          return Image.file(
            File(data),
            width: 200.0,
            height: 200.0,
          );
        } else {
          return Container(
            child: SizedBox(
              child: CircularProgressIndicator(),
              width: 35.0,
              height: 35.0,
            ),
            alignment: Alignment.center,
          );
        }
      },
      future: data.thumb,
    );
  }
}
