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
    var item = widget.photos[index];
    // SystemChannels
    return FutureBuilder<File>(
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        // print("snapshot.connectionState state = ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          var data = snapshot.data;
          // print(data);
          return GestureDetector(
            child: Image.file(
              data,
              width: 200.0,
              height: 200.0,
            ),
            onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => BigImage(
                          entity: item,
                        ),
                  ),
                ),
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
      future: item.thumb,
    );
  }
}

class BigImage extends StatefulWidget {
  final ImageEntity entity;

  const BigImage({Key key, this.entity}) : super(key: key);

  @override
  BigImageState createState() {
    return new BigImageState();
  }
}

class BigImageState extends State<BigImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('大图'),
      ),
      body: Container(
        child: FutureBuilder<List<int>>(
          builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
            print("snapshot.connectionState = ${snapshot.connectionState}");
            print("snapshot.data = ${snapshot.data}");
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return Image.memory(
                snapshot.data,
                width: double.infinity,
                height: double.infinity,
              );
            }
            return Container();
          },
          future: widget.entity.fullData,
        ),
      ),
    );
  }
}
