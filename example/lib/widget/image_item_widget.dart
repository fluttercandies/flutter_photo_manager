import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageItemWidget extends StatefulWidget {
  const ImageItemWidget({
    Key? key,
    required this.entity,
    required this.option,
  }) : super(key: key);

  final AssetEntity entity;
  final ThumbOption option;

  @override
  _ImageItemWidgetState createState() => _ImageItemWidgetState();
}

class _ImageItemWidgetState extends State<ImageItemWidget> {
  @override
  void didUpdateWidget(ImageItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id) {
      setState(() {});
    }
  }

  Widget buildContent(BuildContext context) {
    if (widget.entity.type == AssetType.audio) {
      return const Center(
        child: Icon(Icons.audiotrack, size: 30),
      );
    }
    return _buildImageWidget(widget.entity, widget.option);
  }

  Widget _buildImageWidget(AssetEntity entity, ThumbOption option) {
    return Image(
      image: AssetEntityImageProvider(
        entity,
        isOriginal: false,
        thumbSize: <int>[option.width, option.height],
        thumbFormat: option.format,
      ),
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildContent(context);
  }
}
