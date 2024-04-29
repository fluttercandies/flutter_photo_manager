import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/image_list.dart';

class PathPage extends StatefulWidget {
  const PathPage({super.key, required this.path});
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
  const GalleryWidget({super.key, required this.path});

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
      if (mounted) {
        _list = list;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ImageList(list: _list);
  }
}
