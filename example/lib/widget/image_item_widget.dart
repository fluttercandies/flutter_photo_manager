import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';
import 'change_notifier_builder.dart';

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
  Widget build(BuildContext context) {
    final PhotoProvider provider = Provider.of<PhotoProvider>(context);
    return ChangeNotifierBuilder<PhotoProvider>(
      value: provider,
      builder: (BuildContext c, Object? p) {
        final ThumbFormat format = provider.thumbFormat;
        return buildContent(format);
      },
    );
  }

  Widget buildContent(ThumbFormat format) {
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
        thumbSize: <int>[option.width, option.height],
        thumbFormat: option.format,
      ),
      fit: BoxFit.cover,
    );
  }

  @override
  void didUpdateWidget(ImageItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id) {
      setState(() {});
    }
  }
}
