import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_scanner/image_scanner.dart';

class PhotoPage extends StatefulWidget {
  final ImageParentPath pathEntity;
  final List<ImageEntity> photos;

  const PhotoPage({Key key, this.pathEntity, this.photos}) : super(key: key);

  @override
  _PhotoPageState createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pathEntity.name),
      ),
      body: FutureBuilder<bool>(
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data != null) {
            return _buildGrid();
          }
          return Center(
            child: Text('加载中...'),
          );
        },
        future: _getThumbFuture(0),
        // future: ImageScanner.createThumbWithIndex(widget.pathEntity, start: 0, end: 100),
      ),
    );
  }

  _buildGrid() {
    return NotificationListener(
      onNotification: _handlerNotify,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.0,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
        ),
        itemBuilder: _buildItem,
        itemCount: widget.photos.length,
      ),
    );
  }

  int page = 0;

  Map<int, Future> pageThumbFuture = {};

  var count = 0;

  _getThumbFuture(int page) {
    var future = pageThumbFuture[page];
    if (future == null) {
      future = ImageScanner.createThumbWithIndex(
        widget.pathEntity,
        start: page * 100,
        end: (page + 1) * 100,
      );
      pageThumbFuture[page] = future;
    }
    return future;
  }

  Widget _buildItem(BuildContext context, int index) {
    if (scrolling && !set.contains(index)) {
      return Container(
        color: Colors.black38,
      );
    }

    // var page = index ~/ 100;
    // var future = _getThumbFuture(page);
    // var c = Completer();
    // var future = c.future;
    // c.complete();

    var item = widget.photos[index];
    var child = FutureBuilder<List<int>>(
      builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null && !scrolling) {
          set.add(index);
          var data = snapshot.data;
          // print(data.absolute.path);
          return GestureDetector(
            child: Image.memory(
              Uint8List.fromList(data),
              width: 200.0,
              height: 200.0,
              fit: BoxFit.contain,
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
          count++;
          return Container(
            child: SizedBox(
              child: Text('loading'),
              width: 35.0,
              height: 35.0,
            ),
            alignment: Alignment.center,
          );
        }
      },
      future: item.thumbData,
    );
    return child;
    // return FutureBuilder(
    //   future: future,
    //   builder: (ctx, shot) {
    //     if (shot.data == null) {
    //       return Container(
    //         child: SizedBox(
    //           child: FlutterLogo(),
    //           width: 35.0,
    //           height: 35.0,
    //         ),
    //         alignment: Alignment.center,
    //       );
    //     }
    //     return child;
    //   },
    // );
  }

  bool scrolling = false;

  Set<int> set = Set();

  bool _handlerNotify(Notification notification) {
    if (notification is ScrollStartNotification) {
      scrolling = true;
    }

    if (notification is ScrollEndNotification) {
      scrolling = false;
      setState(() {});
    }

    // if (notification is ScrollUpdateNotification) {
    //   // print(notification.dragDetails);
    // }
    return false;
  }
}

class SmallItem extends StatefulWidget {
  final ImageEntity entity;
  final bool isShow;

  const SmallItem({Key key, this.entity, this.isShow}) : super(key: key);

  @override
  _SmallItemState createState() => _SmallItemState();
}

class _SmallItemState extends State<SmallItem> {
  @override
  Widget build(BuildContext context) {
    return Container();
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
        child: FutureBuilder<File>(
          builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
            var data = snapshot.data;
            if (snapshot.connectionState == ConnectionState.done && data != null) {
              // print(data.lengthSync());
              // print(data.absolute.path);
              return Image.file(
                data,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.contain,
              );
            }
            return Container();
          },
          future: widget.entity.file,
        ),
      ),
    );
  }
}
