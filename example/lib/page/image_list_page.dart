import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_scanner_example/develop/upload_to_dev_serve.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/page/detail_page.dart';
import 'package:image_scanner_example/widget/change_notifier_builder.dart';
import 'package:image_scanner_example/widget/dialog/list_dialog.dart';
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
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.info_outline,
                    size: 22,
                  ),
                ),
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

    Widget previewOriginBytesWidget;

    if (entity.type != AssetType.image) {
      previewOriginBytesWidget = Container();
    } else {
      previewOriginBytesWidget = RaisedButton(
        child: Text("Show origin bytes image in dialog"),
        onPressed: () => showOriginBytes(entity),
      );
    }

    return GestureDetector(
      onTap: () async {
        showDialog(
          context: context,
          builder: (_) => ListDialog(
            children: <Widget>[
              previewOriginBytesWidget,
              RaisedButton(
                child: Text("Show thumb image in dialog"),
                onPressed: () => showThumbImageDialog(entity, entity.width, entity.height),
              ),
              RaisedButton(
                child: Text("Show detail page"),
                onPressed: () => routeToDetailPage(entity),
              ),
              RaisedButton(
                child: Text("Delete item"),
                onPressed: () => _deleteCurrent(entity),
              ),
              RaisedButton(
                child: Text("Upload to my test server."),
                onPressed: () => UploadToDevServer().upload(entity),
              ),
            ],
          ),
        );
        // routeToDetailPage(entity);
      },
      child: ImageItemWidget(
        key: ValueKey(entity),
        entity: entity,
      ),
    );
  }

  void routeToDetailPage(AssetEntity entity) async {
    final originFile = await entity.originFile;
    if (originFile == null || !originFile.existsSync()) {
      print("data length = ${originFile?.lengthSync()}");
      showToast(
        "The file is null, please see issue #128.",
        duration: const Duration(milliseconds: 3500),
      );
      return;
    }
    print(
        "origin file length = ${originFile.lengthSync()}, path = ${originFile.absolute.path}");
    final page = DetailPage(
      file: originFile,
      entity: entity,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
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

  showOriginBytes(AssetEntity entity) {
    print("entity.title = ${entity.title}");
    if (entity.title.toLowerCase().endsWith(".heic")) {
      showToast("Heic no support by Flutter.");
      return;
    }
    showDialog(
        context: context,
        builder: (_) {
          return FutureBuilder<Uint8List>(
            future: entity.originBytes,
            builder: (BuildContext context, snapshot) {
              Widget w;
              if (snapshot.hasData) {
                w = Image.memory(snapshot.data);
              } else {
                w = Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return GestureDetector(
                child: w,
                onTap: () => Navigator.pop(context),
              );
            },
          );
        });
  }

  void showThumbImageDialog(AssetEntity entity, int width, int height) async {
    final format = ThumbFormat.jpeg;
    // final format = ThumbFormat.png;

    showDialog(
        context: context,
        builder: (_) {
          return FutureBuilder<Uint8List>(
            future: entity.thumbDataWithSize(width, height, format: format),
            builder: (BuildContext context, snapshot) {
              Widget w;
              if (snapshot.hasData) {
                print("$format image length : ${snapshot.data.length}");
                w = Image.memory(snapshot.data);
              } else {
                w = Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return GestureDetector(
                child: w,
                onTap: () => Navigator.pop(context),
              );
            },
          );
        });
  }
}
