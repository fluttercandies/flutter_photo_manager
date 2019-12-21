import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/page/detail_page.dart';
import 'package:image_scanner_example/widget/change_notifier_builder.dart';
import 'package:image_scanner_example/widget/image_item_widget.dart';
import 'package:image_scanner_example/widget/loading_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class GalleryContentListPage extends StatefulWidget {
  final AssetPathEntity path;

  const GalleryContentListPage({Key key, this.path}) : super(key: key);

  @override
  _GalleryContentListPageState createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  PathProvider get provider =>
      Provider.of<PhotoProvider>(context).getOrCreatePathProvider(path);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder(
      value: provider,
      builder: (_, __) {
        var length = path.assetCount;
        return Scaffold(
          appBar: AppBar(
            title: Text("${path.name}"),
            actions: <Widget>[
              Tooltip(
                child: Icon(Icons.info_outline),
                message: "Long tap to delete item.",
              ),
            ],
          ),
          body: buildRefreshIndicator(length),
        );
      },
    );
  }

  Widget buildRefreshIndicator(int length) {
    if (!provider.isInit) {
      provider.onRefresh();
      return Center(
        child: Text("loading"),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Scrollbar(
        child: GridView.builder(
          itemBuilder: _buildItem,
          itemCount: provider.showItemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final list = provider.list;
    if (list.length == index) {
      onLoadMore();
      return loadWidget;
    }

    if (index > list.length) {
      return Container();
    }

    final entity = list[index];
    return GestureDetector(
      onTap: () async {
        final f = await entity.file;
        if (f == null) {
          final data = await entity.fullData;
          print("data length = ${data?.length}");
          showToast(
            "The file is null, please see issue #128.",
            duration: const Duration(milliseconds: 3500),
          );
          return;
        }
        final page = DetailPage(
          file: f,
          entity: entity,
        );
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (BuildContext context) {
          return page;
        }));
      },
      onLongPress: () => _deleteCurrent(entity),
      child: ImageItemWidget(
        key: ValueKey(entity),
        entity: entity,
      ),
    );
  }

  Future<void> onLoadMore() async {
    if (!mounted) {
      return;
    }
    await provider.onLoadMore();
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await provider.onRefresh();
  }

  void _deleteCurrent(AssetEntity entity) async {
    if (Platform.isAndroid) {
      final dialog = AlertDialog(
        title: Text("Delete the asset"),
        actions: <Widget>[
          FlatButton(
            child: Text(
              "delete",
              style: const TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              provider.delete(entity);
              Navigator.pop(context);
            },
          ),
          FlatButton(
            child: Text("cancel"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      showDialog(context: context, builder: (_) => dialog);
    } else {
      provider.delete(entity);
    }
  }
}
