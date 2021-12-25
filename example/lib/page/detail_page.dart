import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../util/common_util.dart';
import '../widget/video_widget.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({
    Key? key,
    required this.entity,
    this.mediaUrl,
  }) : super(key: key);

  final AssetEntity entity;
  final String? mediaUrl;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool? useOrigin = true;

  @override
  Widget build(BuildContext context) {
    final CheckboxListTile originCheckbox = CheckboxListTile(
      title: const Text('Use origin file.'),
      onChanged: (bool? value) {
        useOrigin = value;
        setState(() {});
      },
      value: useOrigin,
    );
    final List<Widget> children = <Widget>[
      Container(
        color: Colors.black,
        child: _buildContent(),
      ),
    ];

    if (widget.entity.type == AssetType.image) {
      children.insert(0, originCheckbox);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset detail'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: ListView(
        children: children,
      ),
    );
  }

  Widget _buildContent() {
    if (widget.entity.type == AssetType.video) {
      return buildVideo();
    } else if (widget.entity.type == AssetType.audio) {
      return buildVideo();
    } else {
      return buildImage();
    }
  }

  Widget buildImage() {
    return Image(
      image: AssetEntityImageProvider(
        widget.entity,
        isOriginal: useOrigin == true,
      ),
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? progress,
      ) {
        if (progress != null) {
          final double? value;
          if (progress.expectedTotalBytes != null) {
            value = progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
          } else {
            value = null;
          }
          return Center(
            child: SizedBox.fromSize(
              size: const Size.square(30),
              child: CircularProgressIndicator(value: value),
            ),
          );
        }
        return child;
      },
    );
  }

  Widget buildVideo() {
    if (widget.mediaUrl == null) {
      return const SizedBox.shrink();
    }
    return VideoWidget(
      isAudio: widget.entity.type == AssetType.audio,
      mediaUrl: widget.mediaUrl!,
    );
  }

  Future<void> _showInfo() {
    return CommonUtil.showInfoDialog(context, widget.entity);
  }

  Widget buildAudio() {
    return const Center(child: Icon(Icons.audiotrack));
  }
}
