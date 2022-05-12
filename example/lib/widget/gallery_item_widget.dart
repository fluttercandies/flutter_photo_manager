import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import '../page/image_list_page.dart';
import '../page/sub_gallery_page.dart';

import 'dialog/list_dialog.dart';

class GalleryItemWidget extends StatelessWidget {
  const GalleryItemWidget({
    Key? key,
    required this.path,
    required this.setState,
  }) : super(key: key);

  final AssetPathEntity path;
  final ValueSetter<VoidCallback> setState;

  Widget buildGalleryItemWidget(AssetPathEntity item, BuildContext context) {
    return GestureDetector(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('count : ${item.assetCount}'),
        trailing: _buildSubButton(item),
      ),
      onTap: () {
        if (item.assetCount == 0) {
          showToast('The asset count is 0.');
          return;
        }
        if (item.albumType == 2) {
          showToast("The folder can't get asset");
          return;
        }

        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => GalleryContentListPage(
              path: item,
            ),
          ),
        );
      },
      onLongPress: () => showDialog<void>(
        context: context,
        builder: (_) {
          return ListDialog(
            children: <Widget>[
              ElevatedButton(
                child: Text('Delete self (${item.name})'),
                onPressed: () async {
                  if (!(Platform.isIOS || Platform.isMacOS)) {
                    showToast('The function only support iOS.');
                    return;
                  }
                  PhotoManager.editor.iOS.deletePath(path);
                },
              ),
              ElevatedButton(
                child: const Text('Show modified date'),
                onPressed: () async {
                  showToast('modified date = ${item.lastModified}');
                },
              ),
            ],
          );
        },
      ),
      // onDoubleTap: () async {
      //   final list =
      //       await item.getAssetListRange(start: 0, end: item.assetCount);
      //   for (var i = 0; i < list.length; i++) {
      //     final asset = list[i];
      //   }
      // },
    );
  }

  Widget _buildSubButton(AssetPathEntity item) {
    if (item.isAll || item.albumType == 2) {
      return Builder(
        builder: (BuildContext ctx) => ElevatedButton(
          onPressed: () async {
            final List<AssetPathEntity> sub = await item.getSubPathList();
            // ignore: use_build_context_synchronously
            Navigator.push(
              ctx,
              MaterialPageRoute<void>(
                builder: (_) => SubFolderPage(title: item.name, pathList: sub),
              ),
            );
          },
          child: const Text('folder'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return buildGalleryItemWidget(path, context);
  }
}
