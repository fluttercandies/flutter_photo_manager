import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/widget/image_item_widget.dart';

class ImageList extends StatelessWidget {
  const ImageList({super.key, required this.list});

  final List<AssetEntity> list;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final entity = list[index];
        return ImageItemWidget(
          entity: entity,
          option: ThumbnailOption.ios(
            size: const ThumbnailSize.square(500),
          ),
        );
      },
      itemCount: list.length,
    );
  }
}
