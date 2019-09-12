import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_scanner_example/page/detail_page.dart';
import 'package:image_scanner_example/widget/image_item_widget.dart';
import 'package:image_scanner_example/widget/loading_widget.dart';
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
      return loadWidget;
    }

    final entity = list[index];
    return GestureDetector(
      onTap: () async {
        final f = await entity.file;
        final page = DetailPage(
          file: f,
        );
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (BuildContext context) {
          return page;
        }));
      },
      child: ImageItemWidget(
        key: ValueKey(entity),
        entity: entity,
      ),
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
