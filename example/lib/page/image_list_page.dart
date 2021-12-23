import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../develop/upload_to_dev_serve.dart';
import '../model/photo_provider.dart';
import '../util/common_util.dart';
import '../widget/dialog/list_dialog.dart';
import '../widget/image_item_widget.dart';
import '../widget/loading_widget.dart';

import 'copy_to_another_gallery_example.dart';
import 'detail_page.dart';
import 'move_to_another_gallery_example.dart';

class GalleryContentListPage extends StatefulWidget {
  const GalleryContentListPage({
    Key? key,
    required this.path,
  }) : super(key: key);

  final AssetPathEntity path;

  @override
  _GalleryContentListPageState createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  AssetPathEntity get path => widget.path;

  PhotoProvider get photoProvider => Provider.of<PhotoProvider>(context);

  AssetPathProvider readPathProvider(BuildContext c) =>
      c.read<AssetPathProvider>();

  AssetPathProvider watchPathProvider(BuildContext c) =>
      c.watch<AssetPathProvider>();

  List<AssetEntity> checked = <AssetEntity>[];

  @override
  void initState() {
    super.initState();
    path
        .getAssetListRange(start: 0, end: path.assetCount)
        .then((List<AssetEntity> value) {
      if (value.isEmpty) {
        return;
      }
      if (mounted) {
        return;
      }
      PhotoCachingManager().requestCacheAssets(
        assets: value,
        option: thumbOption,
      );
    });
  }

  @override
  void dispose() {
    PhotoCachingManager().cancelCacheRequest();
    super.dispose();
  }

  ThumbOption get thumbOption => ThumbOption(
        width: 130,
        height: 130,
        format: photoProvider.thumbFormat,
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssetPathProvider>(
      create: (_) => AssetPathProvider(widget.path),
      builder: (BuildContext context, _) => Scaffold(
        appBar: AppBar(
          title: Text(path.name),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.delete,
              ),
              tooltip: 'Delete selected ',
              onPressed: () {
                readPathProvider(context);
              },
            ),
            AnimatedBuilder(
              animation: photoProvider,
              builder: (_, __) {
                final ThumbFormat formatType =
                    photoProvider.thumbFormat == ThumbFormat.jpeg
                        ? ThumbFormat.png
                        : ThumbFormat.jpeg;
                return IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  iconSize: 22,
                  tooltip: 'Use another format.',
                  onPressed: () {
                    photoProvider.thumbFormat = formatType;
                  },
                );
              },
            ),
            const Tooltip(
              message: 'Long tap to delete item.',
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        body: buildRefreshIndicator(context, path.assetCount),
      ),
    );
  }

  Widget buildRefreshIndicator(BuildContext context, int length) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: Scrollbar(
        child: GridView.builder(
          itemBuilder: _buildItem,
          itemCount: watchPathProvider(context).showItemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final List<AssetEntity> list = watchPathProvider(context).list;
    if (list.length == index) {
      onLoadMore(context);
      return loadWidget;
    }

    if (index > list.length) {
      return Container();
    }

    final AssetEntity entity = list[index];

    Widget previewOriginBytesWidget;

    if (entity.type != AssetType.image) {
      previewOriginBytesWidget = Container();
    } else {
      previewOriginBytesWidget = ElevatedButton(
        child: const Text('Show origin bytes image in dialog'),
        onPressed: () => showOriginBytes(entity),
      );
    }

    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => ListDialog(
          children: <Widget>[
            previewOriginBytesWidget,
            ElevatedButton(
              child: const Text('isLocallyAvailable'),
              onPressed: () => entity.isLocallyAvailable.then(
                (bool r) => print('isLocallyAvailable: $r'),
              ),
            ),
            ElevatedButton(
              child: const Text('getMediaUrl'),
              onPressed: () async {
                final Stopwatch watch = Stopwatch()..start();
                final String? url = await entity.getMediaUrl();
                watch.stop();
                print('Media URL: $url');
                print(watch.elapsed);
              },
            ),
            ElevatedButton(
              child: const Text('Show detail page'),
              onPressed: () => routeToDetailPage(entity),
            ),
            ElevatedButton(
              child: const Text('Show info dialog'),
              onPressed: () => CommonUtil.showInfoDialog(context, entity),
            ),
            ElevatedButton(
              child: const Text('show 500 size thumb '),
              onPressed: () => showThumb(entity, 500),
            ),
            ElevatedButton(
              child: const Text('Delete item'),
              onPressed: () => _deleteCurrent(entity),
            ),
            ElevatedButton(
              child: const Text('Upload to my test server.'),
              onPressed: () => UploadToDevServer.upload(entity),
            ),
            ElevatedButton(
              child: const Text('Copy to another path'),
              onPressed: () => copyToAnotherPath(entity),
            ),
            _buildMoveAnotherPath(entity),
            _buildRemoveInAlbumWidget(entity),
            ElevatedButton(
              child: const Text('Test progress'),
              onPressed: () => testProgressHandler(entity),
            ),
            ElevatedButton(
              child: const Text('Test thumb size'),
              onPressed: () => testThumbSize(
                entity,
                <int>[500, 600, 700, 1000, 1500, 2000],
              ),
            ),
          ],
        ),
      ),
      onLongPress: () {
        if (checked.contains(entity)) {
          checked.remove(entity);
        } else {
          checked.add(entity);
        }
        setState(() {});
      },
      child: Stack(
        children: <Widget>[
          ImageItemWidget(
            key: ValueKey<AssetEntity>(entity),
            entity: entity,
            option: thumbOption,
          ),
          Align(
            alignment: Alignment.topRight,
            child: Checkbox(
              value: checked.contains(entity),
              onChanged: (bool? value) {
                if (checked.contains(entity)) {
                  checked.remove(entity);
                } else {
                  checked.add(entity);
                }
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> routeToDetailPage(AssetEntity entity) async {
    final String? mediaUrl = await entity.getMediaUrl();
    if (!mounted) {
      return;
    }
    final DetailPage page = DetailPage(
      entity: entity,
      mediaUrl: mediaUrl,
    );
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> onLoadMore(BuildContext context) async {
    if (!mounted) {
      return;
    }
    await readPathProvider(context).onLoadMore();
  }

  Future<void> _onRefresh(BuildContext context) async {
    if (!mounted) {
      return;
    }
    await readPathProvider(context).onRefresh();
  }

  Future<void> _deleteCurrent(AssetEntity entity) async {
    if (Platform.isAndroid) {
      final AlertDialog dialog = AlertDialog(
        title: const Text('Delete the asset'),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              readPathProvider(context).delete(entity);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      showDialog<void>(context: context, builder: (_) => dialog);
    } else {
      readPathProvider(context).delete(entity);
    }
  }

  Future<void> showOriginBytes(AssetEntity entity) async {
    final String title;
    if (entity.title?.isEmpty != false) {
      title = await entity.titleAsync;
    } else {
      title = entity.title!;
    }
    print('entity.title = $title');
    showDialog<void>(
      context: context,
      builder: (_) {
        return FutureBuilder<Uint8List?>(
          future: entity.originBytes,
          builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
            Widget w;
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            } else if (snapshot.hasData) {
              w = Image.memory(snapshot.data!);
            } else {
              w = Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            return GestureDetector(
              child: w,
              onTap: () => Navigator.pop(context),
            );
          },
        );
      },
    );
  }

  Future<void> copyToAnotherPath(AssetEntity entity) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CopyToAnotherGalleryPage(assetEntity: entity),
      ),
    );
  }

  Widget _buildRemoveInAlbumWidget(AssetEntity entity) {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      return Container();
    }

    return ElevatedButton(
      child: const Text('Remove in album'),
      onPressed: () => deleteAssetInAlbum(entity),
    );
  }

  void deleteAssetInAlbum(AssetEntity entity) {
    readPathProvider(context).removeInAlbum(entity);
  }

  Widget _buildMoveAnotherPath(AssetEntity entity) {
    if (!Platform.isAndroid) {
      return Container();
    }
    return ElevatedButton(
      onPressed: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MoveToAnotherExample(entity: entity),
        ),
      ),
      child: const Text('Move to another gallery.'),
    );
  }

  Future<void> showThumb(AssetEntity entity, int size) async {
    final String title;
    if (entity.title?.isEmpty != false) {
      title = await entity.titleAsync;
    } else {
      title = entity.title!;
    }
    print('entity.title = $title');
    return showDialog(
      context: context,
      builder: (_) {
        return FutureBuilder<Uint8List?>(
          future: entity.thumbDataWithOption(
            ThumbOption.ios(
              width: 500,
              height: 500,
              // resizeContentMode: ResizeContentMode.fill,
            ),
          ),
          builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
            Widget w;
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            } else if (snapshot.hasData) {
              final Uint8List data = snapshot.data!;
              ui.decodeImageFromList(data, (ui.Image result) {
                print('result size: ${result.width}x${result.height}');
                // for 4288x2848
              });
              w = Image.memory(data);
            } else {
              w = Center(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            return GestureDetector(
              child: w,
              onTap: () => Navigator.pop(context),
            );
          },
        );
      },
    );
  }

  Future<void> testProgressHandler(AssetEntity entity) async {
    final PMProgressHandler progressHandler = PMProgressHandler();
    progressHandler.stream.listen((PMProgressState event) {
      final double progress = event.progress;
      print('progress state onChange: ${event.state}, progress: $progress');
    });
    // final file = await entity.loadFile(progressHandler: progressHandler);
    // print('file = $file');

    // final thumb = await entity.thumbDataWithSize(
    //   300,
    //   300,
    //   progressHandler: progressHandler,
    // );

    // print('thumb length = ${thumb.length}');

    final File? file = await entity.loadFile(
      progressHandler: progressHandler,
    );
    print('file = $file');
  }

  Future<void> testThumbSize(AssetEntity entity, List<int> list) async {
    for (final int size in list) {
      // final data = await entity.thumbDataWithOption(ThumbOption.ios(
      //   width: size,
      //   height: size,
      //   resizeMode: ResizeMode.exact,
      // ));
      final Uint8List? data = await entity.thumbDataWithSize(size, size);

      if (data == null) {
        return;
      }
      ui.decodeImageFromList(data, (ui.Image result) {
        print(
          'size: $size, '
          'length: ${data.length}, '
          'width*height: ${result.width}x${result.height}',
        );
      });
    }
  }
}
