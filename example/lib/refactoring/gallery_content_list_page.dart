import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryContentListPage extends StatefulWidget {
  final AssetPathEntity path;

  const GalleryContentListPage({Key key, this.path}) : super(key: key);
  @override
  _GalleryContentListPageState createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  List<AssetEntity> list = [];

  var page = 0;

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    var length = path.assetCount;

    if (list.length < length) {
      length = list.length + 1;
    }

    return Scaffold(
      appBar: AppBar(),
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
      return Center(
        child: SizedBox.fromSize(
          size: Size.square(44),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final item = list[index];
    return AspectRatio(
      aspectRatio: 1,
      child: FutureBuilder<Uint8List>(
        future: Plugin().getThumb(id: item.id, width: 130, height: 130),
        // future: Plugin().getOriginBytes(item.id),
        builder: (context, snapshot) {
          Widget w;
          if (snapshot.hasError) {
            w = Text("error");
          }
          if (snapshot.hasData) {
            w = Image.memory(snapshot.data);
          } else {
            w = Text("no data");
          }

          return Stack(
            children: <Widget>[
              w,
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 80,
                  height: 20,
                  child: Text(item.typeInt.toString()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void initData() async {
    final list = await path.getAssetListPaged(0, loadCount);

    print(list.length);

    this.list.addAll(list);
    setState(() {});
  }

  final loadCount = 32;

  Future<void> onLoadMore() async {
    print("on load more");
    final list = await path.getAssetListPaged(page + 1, loadCount);
    page = page + 1;
    this.list.clear();
    this.list.addAll(list);
    setState(() {});
  }

  Future<void> _onRefresh() async {
    final list = await path.getAssetListPaged(0, loadCount);
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    setState(() {});
  }
}
