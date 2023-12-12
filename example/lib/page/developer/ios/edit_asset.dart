import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class EditAssetPage extends StatefulWidget {
  const EditAssetPage({super.key});

  @override
  State<EditAssetPage> createState() => _EditAssetPageState();
}

class _EditAssetPageState extends State<EditAssetPage> {
  AssetEntity? entity;

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test edit asset.'),
      ),
      body: entity == null
          ? Container()
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1,
                    child: FutureBuilder<Uint8List?>(
                      future: entity!.originBytes,
                      builder: (_, AsyncSnapshot<Uint8List?> s) {
                        if (!s.hasData) {
                          return Container();
                        }
                        return Image.memory(s.data!);
                      },
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: FutureBuilder<File?>(
                      future: entity!.file,
                      builder: (_, AsyncSnapshot<File?> s) {
                        if (!s.hasData) {
                          return Container();
                        }
                        return Image.file(s.data!);
                      },
                    ),
                  ),
                  // AspectRatio(
                  //   aspectRatio: 1,
                  //   child: FutureBuilder<File>(
                  //     future: entity.originFile,
                  //     builder: (_, s) {
                  //       if (!s.hasData) {
                  //         return Container();
                  //       }
                  //       return Image.file(s.data);
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ),
    );
  }

  Future<void> initData() async {
    final List<AssetPathEntity> pathList = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    final List<AssetEntity> list =
        await pathList[0].getAssetListRange(start: 0, end: 1);
    final AssetEntity asset = list[0];
    entity = asset;
    setState(() {});
  }
}
