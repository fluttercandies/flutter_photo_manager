import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/developer/issues_page/issue_index_page.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class Issue988 extends StatefulWidget {
  const Issue988({super.key});

  @override
  State<Issue988> createState() {
    return _Issue988State();
  }
}

class _Issue988State extends State<Issue988> with IssueBase {
  @override
  void initState() {
    super.initState();
    PhotoManager.requestPermissionExtend().then((value) => loadGallery());
  }

  List<AssetPathEntity> filterList = [];
  List<AssetPathEntity> list = [];

  Future<void> loadGallery() async {
    final list = await PhotoManager.getAssetPathList(
      hasAll: true,
      type: RequestType.all,
      filterOption: PMFilter.defaultValue(),
    );
    print('list.length ${list.length}');
    setState(() {
      this.list = list;
      filterList = list;
    });
  }

  Widget galleryList() {
    final size = MediaQuery.of(context).size;
    final halfHeight = size.height / 2;
    return ListView.builder(
      itemBuilder: (ctx, i) {
        final path = filterList[i];
        return buildButton(
          path.name,
          () {
            Scaffold.of(ctx).showBottomSheet(
              (context) => SizedBox(
                height: halfHeight,
                child: _DeleteAssetImageList(
                  path: path,
                ),
              ),
            );
          },
        );
      },
      itemCount: filterList.length,
    );
  }

  Widget filterWithName() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Filter with name',
      ),
      onChanged: (value) {
        filterList = list.where((element) {
          return element.name.toLowerCase().contains(value.toLowerCase());
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold([
      filterWithName(),
      Expanded(child: galleryList()),
    ]);
  }

  @override
  int get issueNumber => 988;
}

class _DeleteAssetImageList extends StatefulWidget {
  const _DeleteAssetImageList({
    required this.path,
  });

  final AssetPathEntity path;

  @override
  State<_DeleteAssetImageList> createState() => __DeleteAssetImageListState();
}

class __DeleteAssetImageListState extends State<_DeleteAssetImageList> {
  final List<AssetEntity> assetList = [];

  final List<AssetEntity> checked = [];

  @override
  void initState() {
    super.initState();
    loadAssets();
  }

  Future<void> loadAssets({int count = 100}) async {
    widget.path;

    widget.path.getAssetListRange(start: 0, end: count).then(
          (value) => setState(() {
            assetList.clear();
            assetList.addAll(value);
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                alignment: Alignment.center,
                color: Colors.grey[300],
                child: const Text(
                  'Just for test, delete the image, so just show 100 images',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                // display the bottom sheet
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_drop_down),
            ),
          ],
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemBuilder: (ctx, i) {
              final asset = assetList[i];
              return Stack(
                children: [
                  AssetEntityImage(
                    asset,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    thumbnailSize: const ThumbnailSize(100, 100),
                    thumbnailFormat: ThumbnailFormat.jpeg,
                    filterQuality: FilterQuality.low,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Checkbox(
                      value: checked.contains(asset),
                      onChanged: (bool? value) {
                        if (value == true) {
                          checked.add(asset);
                        } else {
                          checked.remove(asset);
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ],
              );
            },
            itemCount: assetList.length,
          ),
        ),
        if (checked.isNotEmpty) _buildDeleteButton(),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: () async {
        // confirm first
        final result = await showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Are you sure to delete these images?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );

        if (result != true) {
          showToast('Cancel delete');
          return;
        }

        final ids = await PhotoManager.editor
            .deleteWithIds(checked.map((e) => e.id).toList());

        showToast('Delete success, ids: $ids');

        if (ids.isNotEmpty) {
          checked.removeWhere((element) => ids.contains(element.id));
        }

        // refresh the list
        loadAssets();
      },
      icon: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
    );
  }
}
