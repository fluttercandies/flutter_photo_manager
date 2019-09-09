import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_scanner_example/core/lru_map.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryContentListPage extends StatefulWidget {
  final AssetPathEntity path;

  const GalleryContentListPage({Key key, this.path}) : super(key: key);
  @override
  _GalleryContentListPageState createState() => _GalleryContentListPageState();
}

Widget _loadWidget = Center(
  child: SizedBox.fromSize(
    size: Size.square(30),
    child: Platform.isIOS
        ? CupertinoActivityIndicator()
        : CircularProgressIndicator(),
  ),
);

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  List<AssetEntity> list = [];

  var page = 0;

  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    var length = path.assetCount;

    if (list.length == 0) {
      length = 0;
    } else if (list.length < length) {
      length = list.length + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${path.name}"),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: GridView.builder(
          itemBuilder: _buildItem,
          itemCount: length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    if (list.length == index) {
      onLoadMore();
      return _loadWidget;
    }

    final entity = list[index];
    return ItemWidget(
      key: ValueKey(entity),
      entity: entity,
    );
  }

  final loadCount = 80;

  Future<void> onLoadMore() async {
    if (!mounted) {
      print("on load more, but it's unmounted");
      return;
    }
    print("on load more");
    final list = await path.getAssetListPaged(page + 1, loadCount);
    page = page + 1;
    this.list.addAll(list);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    final list = await path.getAssetListPaged(0, loadCount);
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    setState(() {});
    if (mounted) {
      setState(() {});
    }
  }
}

class ItemWidget extends StatefulWidget {
  final AssetEntity entity;

  const ItemWidget({
    Key key,
    this.entity,
  }) : super(key: key);
  @override
  _ItemWidgetState createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  @override
  Widget build(BuildContext context) {
    final item = widget.entity;
    final size = 130;
    final u8List = ImageLruCache.getData(item, size);

    Widget image;

    if (u8List != null) {
      image = Image.memory(u8List);
    } else {
      image = FutureBuilder<Uint8List>(
        future: Plugin().getThumb(id: item.id, width: size, height: size),
        // future: Plugin().getOriginBytes(item.id),
        builder: (context, snapshot) {
          Widget w;
          if (snapshot.hasError) {
            w = Center(
              child: Text("load error"),
            );
          }
          if (snapshot.hasData) {
            ImageLruCache.setData(item, size, snapshot.data);
            w = FittedBox(
              fit: BoxFit.cover,
              child: Image.memory(
                snapshot.data,
              ),
            );
          } else {
            w = Center(
              child: _loadWidget,
            );
          }

          return w;
        },
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: image,
    );
  }

  @override
  void didUpdateWidget(ItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id) {
      setState(() {});
    }
  }
}
