import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/widget/image_item_widget.dart';

class PathPage extends StatefulWidget {
  const PathPage({Key? key, required this.path}) : super(key: key);
  final AssetPathEntity path;

  @override
  State<PathPage> createState() => _PathPageState();
}

class _PathPageState extends State<PathPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path.name),
      ),
      body: GalleryWidget(
        path: widget.path,
      ),
    );
  }
}

class GalleryWidget extends StatefulWidget {
  const GalleryWidget({Key? key, required this.path}) : super(key: key);

  final AssetPathEntity path;

  @override
  State<GalleryWidget> createState() => _GalleryWidgetState();
}

class _GalleryWidgetState extends State<GalleryWidget> {
  List<AssetEntity> _list = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await widget.path.assetCountAsync;
    if (count == 0) {
      return;
    }
    final list = await widget.path.getAssetListRange(start: 0, end: count);
    setState(() {
      if (mounted) _list = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final entity = _list[index];
        return ImageItemWidget(
          entity: entity,
          option: ThumbnailOption.ios(
            size: const ThumbnailSize.square(500),
          ),
        );
      },
      itemCount: _list.length,
    );
  }
}
