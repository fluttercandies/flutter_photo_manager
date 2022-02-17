import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageItemWidget extends StatelessWidget {
  const ImageItemWidget({
    Key? key,
    required this.entity,
    required this.option,
    this.onTap,
  }) : super(key: key);

  final AssetEntity entity;
  final ThumbnailOption option;
  final GestureTapCallback? onTap;

  Widget buildContent(BuildContext context) {
    if (entity.type == AssetType.audio) {
      return const Center(
        child: Icon(Icons.audiotrack, size: 30),
      );
    }
    return _buildImageWidget(entity, option);
  }

  Widget _buildImageWidget(AssetEntity entity, ThumbnailOption option) {
    return AssetEntityImage(
      entity,
      isOriginal: false,
      thumbnailSize: option.size,
      thumbnailFormat: option.format,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: buildContent(context),
    );
  }
}
