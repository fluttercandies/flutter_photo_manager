import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PagingPage extends StatefulWidget {
  final AssetPathEntity entity;

  const PagingPage({Key key, this.entity}) : super(key: key);

  @override
  _PagingPageState createState() => _PagingPageState();
}

class _PagingPageState extends State<PagingPage> {
  AssetPathEntity get path => widget.entity;
  List<AssetEntity> list = [];

  int page = 0;

  static const perPage = 14;

  @override
  void initState() {
    super.initState();
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(path.name),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more),
            onPressed: _loadMore,
            tooltip: "load more",
          ),
        ],
      ),
      body: Container(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: GridView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemBuilder: _buildItem,
            itemCount: list.length,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = list[index];
    return FutureBuilder<Uint8List>(
      future: item.thumbDataWithSize(150, 150),
      builder: (BuildContext context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox.fromSize(
              child: CircularProgressIndicator(),
              size: Size.square(44),
            ),
          );
        }
        return Image.memory(snapshot.data);
      },
    );
  }

  Future<void> _loadMore() async {
    final assetList = await path.getAssetListPaged(page, perPage);
    list.addAll(assetList);
    page++;
    setState(() {});
  }

  Future<void> onRefresh() async {
    final assetList = await path.getAssetListPaged(0, perPage);
    list.clear();
    list.addAll(assetList);
    page = 1;
    setState(() {});
  }
}
