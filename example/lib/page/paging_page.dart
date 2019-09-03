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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: RefreshIndicator(
          onRefresh: _onLoadMore,
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
              size: Size.square(100),
            ),
          );
        }
        return Image.memory(snapshot.data);
      },
    );
  }

  Future<void> _onLoadMore() async {
    final assetList = await path.getAssetListPaged(page, 15);
    list.clear();
    list.addAll(assetList);
    setState(() {});
  }
}
