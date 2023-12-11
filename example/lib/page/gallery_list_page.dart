import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';
import '../widget/gallery_item_widget.dart';

class GalleryListPage extends StatefulWidget {
  const GalleryListPage({super.key});

  @override
  State<GalleryListPage> createState() => _GalleryListPageState();
}

class _GalleryListPageState extends State<GalleryListPage> {
  PhotoProvider get provider => context.watch<PhotoProvider>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery list'),
      ),
      body: Scrollbar(
        child: ListView.builder(
          itemBuilder: _buildItem,
          itemCount: provider.list.length,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final AssetPathEntity item = provider.list[index];
    return GalleryItemWidget(
      path: item,
      setState: setState,
    );
  }
}
