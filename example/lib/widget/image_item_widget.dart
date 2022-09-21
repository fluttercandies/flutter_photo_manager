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
    return _buildImageWidget(context, entity, option);
  }

  Widget _buildImageWidget(
    BuildContext context,
    AssetEntity entity,
    ThumbnailOption option,
  ) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AssetEntityImage(
            entity,
            isOriginal: false,
            thumbnailSize: option.size,
            thumbnailFormat: option.format,
            fit: BoxFit.cover,
          ),
        ),
        PositionedDirectional(
          bottom: 4,
          end: 4,
          child: Icon(
            () {
              switch (entity.type) {
                case AssetType.other:
                  return Icons.abc;
                case AssetType.image:
                  return Icons.image;
                case AssetType.video:
                  return Icons.video_file;
                case AssetType.audio:
                  return Icons.audiotrack;
              }
            }(),
            color: Colors.white,
            size: 16,
          ),
        ),
        if (entity.isFavorite)
          PositionedDirectional(
            bottom: 4,
            start: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.redAccent,
                size: 16,
              ),
            ),
          ),
      ],
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
