import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager/platform_utils.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../util/common_util.dart';
import '../widget/live_photos_widget.dart';
import '../widget/video_widget.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.entity});

  final AssetEntity entity;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool? useOrigin = true;
  bool? useMediaUrl = true && !PlatformUtils.isOhos;

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: <Widget>[
          if (widget.entity.type == AssetType.image)
            CheckboxListTile(
              title: const Text('Use origin file.'),
              onChanged: (bool? value) {
                useOrigin = value;
                setState(() {});
              },
              value: useOrigin,
            ),
          if (widget.entity.type == AssetType.video && !PlatformUtils.isOhos)
            CheckboxListTile(
              title: const Text('Use Media Url'),
              value: useMediaUrl,
              onChanged: (bool? value) {
                useMediaUrl = value;
                setState(() {});
              },
            ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.entity.isLivePhoto) {
      return LivePhotosWidget(
        entity: widget.entity,
        useOrigin: useOrigin == true,
      );
    }
    if (widget.entity.type == AssetType.video ||
        widget.entity.type == AssetType.audio ||
        widget.entity.isLivePhoto) {
      return buildVideo();
    }
    return buildImage();
  }

  Widget buildImage() {
    return AssetEntityImage(
      widget.entity,
      isOriginal: useOrigin == true,
      fit: BoxFit.fill,
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? progress,
      ) {
        if (progress == null) {
          return child;
        }
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
      },
    );
  }

  Widget buildVideo() {
    return VideoWidget(
      entity: widget.entity,
      usingMediaUrl: useMediaUrl ?? true,
    );
  }

  Future<void> _showInfo() {
    return CommonUtil.showInfoDialog(context, widget.entity);
  }

  Widget buildAudio() {
    return const Center(child: Icon(Icons.audiotrack));
  }
}
