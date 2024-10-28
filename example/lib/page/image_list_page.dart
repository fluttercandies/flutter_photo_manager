// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';
import '../util/common_util.dart';
import '../util/log.dart';
import '../widget/dialog/list_dialog.dart';
import '../widget/image_item_widget.dart';
import '../widget/loading_widget.dart';

import 'copy_to_another_gallery_example.dart';
import 'detail_page.dart';
import 'move_to_another_gallery_example.dart';

class GalleryContentListPage extends StatefulWidget {
  const GalleryContentListPage({
    super.key,
    required this.path,
  });

  final AssetPathEntity path;

  @override
  State<GalleryContentListPage> createState() => _GalleryContentListPageState();
}

class _GalleryContentListPageState extends State<GalleryContentListPage> {
  late final PhotoProvider photoProvider = Provider.of<PhotoProvider>(context);

  AssetPathEntity get path => widget.path;

  AssetPathProvider readPathProvider(BuildContext c) =>
      c.read<AssetPathProvider>();

  AssetPathProvider watchPathProvider(BuildContext c) =>
      c.watch<AssetPathProvider>();

  @override
  void initState() {
    super.initState();
    path.getAssetListRange(start: 0, end: 1).then((List<AssetEntity> value) {
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

  ThumbnailOption get thumbOption => ThumbnailOption(
        size: const ThumbnailSize.square(200),
        format: photoProvider.thumbFormat,
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssetPathProvider>(
      create: (_) => AssetPathProvider(widget.path),
      builder: (BuildContext context, _) => Scaffold(
        appBar: AppBar(title: Text(path.name)),
        body: buildRefreshIndicator(context),
      ),
    );
  }

  Widget buildRefreshIndicator(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: Scrollbar(
        child: CustomScrollView(
          slivers: <Widget>[
            Consumer<AssetPathProvider>(
              builder: (BuildContext c, AssetPathProvider p, _) => SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, int index) => Builder(
                    builder: (BuildContext c) => _buildItem(context, index),
                  ),
                  childCount: p.showItemCount,
                  findChildIndexCallback: (Key? key) {
                    if (key is ValueKey<String>) {
                      return findChildIndexBuilder(
                        id: key.value,
                        assets: p.list,
                      );
                    }
                    return null;
                  },
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 2,
                  crossAxisCount: 4,
                  crossAxisSpacing: 2,
                ),
              ),
            ),
          ],
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
      return const SizedBox.shrink();
    }
    AssetEntity entity = list[index];
    return ImageItemWidget(
      key: ValueKey<int>(entity.hashCode),
      entity: entity,
      option: thumbOption,
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => ListDialog(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          children: <Widget>[
            if (entity.type == AssetType.image)
              ElevatedButton(
                child: const Text('Show origin bytes image in dialog'),
                onPressed: () => showOriginBytes(entity),
              ),
            ElevatedButton(
              child: const Text('isLocallyAvailable (for .file)'),
              onPressed: () => entity.isLocallyAvailable().then((bool r) {
                Log.d('isLocallyAvailable: $r');
              }),
            ),
            if (entity.type == AssetType.video ||
                entity.type == AssetType.audio)
              ElevatedButton(
                child: const Text('getMediaUrl'),
                onPressed: () async {
                  final Stopwatch watch = Stopwatch()..start();
                  final String? url = await entity.getMediaUrl();
                  watch.stop();
                  Log.d('Media URL: $url');
                  Log.d(watch.elapsed);
                },
              ),
            ElevatedButton(
              child: const Text('Get file'),
              onPressed: () => getFile(entity),
            ),
            if (entity.isLivePhoto)
              ElevatedButton(
                child: const Text('Get MP4 file'),
                onPressed: () => getFileWithMP4(entity),
              ),
            if (entity.isLivePhoto)
              ElevatedButton(
                child: const Text('Get Live Photo duration'),
                onPressed: () => getDurationOfLivePhoto(entity),
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
              onPressed: () => _deleteCurrent(context, entity),
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
            if (Platform.isIOS || Platform.isMacOS || PlatformUtils.isOhos)
              ElevatedButton(
                child: const Text('Toggle isFavorite'),
                onPressed: () async {
                  final bool isFavorite = entity.isFavorite;
                  print('Current isFavorite: $isFavorite');
                  if (PlatformUtils.isOhos) {
                    await PhotoManager.editor.ohos.favoriteAsset(
                      entity: entity,
                      favorite: !isFavorite,
                    );
                  } else {
                    await PhotoManager.editor.darwin.favoriteAsset(
                      entity: entity,
                      favorite: !isFavorite,
                    );
                  }
                  final AssetEntity? newEntity =
                      await entity.obtainForNewProperties();
                  print('New isFavorite: ${newEntity?.isFavorite}');
                  if (!mounted) {
                    return;
                  }
                  if (newEntity != null) {
                    entity = newEntity;
                    readPathProvider(context).list[index] = newEntity;
                    setState(() {});
                  }
                },
              ),
            if ((Platform.isIOS || Platform.isMacOS) && entity.isLivePhoto)
              ElevatedButton(
                onPressed: () {
                  showLivePhotoInfo(entity);
                },
                child: const Text('Show live photo'),
              ),
          ],
        ),
      ),
    );
  }

  int findChildIndexBuilder({
    required String id,
    required List<AssetEntity> assets,
  }) {
    return assets.indexWhere((AssetEntity e) => e.id == id);
  }

  Future<void> getFile(AssetEntity entity) async {
    final file = await entity.file;
    print(file);
  }

  Future<void> getFileWithMP4(AssetEntity entity) async {
    final file = await entity.loadFile(
      isOrigin: false,
      withSubtype: true,
      darwinFileType: PMDarwinAVFileType.mp4,
    );
    print(file);
  }

  Future<void> getDurationOfLivePhoto(AssetEntity entity) async {
    final duration = await entity.durationWithOptions(withSubtype: true);
    print(duration);
  }

  Future<void> routeToDetailPage(AssetEntity entity) async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DetailPage(entity: entity)),
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

  Future<void> _deleteCurrent(BuildContext context, AssetEntity entity) async {
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
    Log.d('entity.title = $title');
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
    Log.d('entity.title = $title');
    return showDialog(
      context: context,
      builder: (_) {
        return FutureBuilder<Uint8List?>(
          future: entity.thumbnailDataWithOption(
            ThumbnailOption.ios(
              size: const ThumbnailSize.square(500),
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
                Log.d('result size: ${result.width}x${result.height}');
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
      Log.d('progress state onChange: ${event.state}, progress: $progress');
    });
    // final file = await entity.loadFile(progressHandler: progressHandler);
    // Log.d('file = $file');

    // final thumb = await entity.thumbDataWithSize(
    //   300,
    //   300,
    //   progressHandler: progressHandler,
    // );

    // Log.d('thumb length = ${thumb.length}');

    final File? file = await entity.loadFile(
      progressHandler: progressHandler,
    );
    Log.d('file = $file');
  }

  Future<void> testThumbSize(AssetEntity entity, List<int> list) async {
    for (final int size in list) {
      // final data = await entity.thumbDataWithOption(ThumbOption.ios(
      //   width: size,
      //   height: size,
      //   resizeMode: ResizeMode.exact,
      // ));
      final Uint8List? data = await entity.thumbnailDataWithSize(
        ThumbnailSize.square(size),
      );

      if (data == null) {
        return;
      }
      ui.decodeImageFromList(data, (ui.Image result) {
        Log.d(
          'size: $size, '
          'length: ${data.length}, '
          'width*height: ${result.width}x${result.height}',
        );
      });
    }
  }

  Future<void> showLivePhotoInfo(AssetEntity entity) async {
    final fileWithSubtype = await entity.originFile;
    final originFileWithSubtype = await entity.originFileWithSubtype;

    print('fileWithSubtype = $fileWithSubtype');
    print('originFileWithSubtype = $originFileWithSubtype');
  }
}
