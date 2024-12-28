import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/path_page.dart';

class FilterPathList extends StatelessWidget {
  const FilterPathList({super.key, required this.filter});

  final CustomFilter filter;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetPathEntity>>(
      future: Future(() async {
        final ps = await PhotoManager.requestPermissionExtend();
        if (!ps.hasAccess) {
          throw StateError('No access');
        }
        return PhotoManager.getAssetPathList(filterOption: filter);
      }),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<AssetPathEntity>> snapshot,
      ) {
        if (snapshot.hasData) {
          return PathList(list: snapshot.data!);
        }
        return const SizedBox();
      },
    );
  }
}

class PathList extends StatelessWidget {
  const PathList({
    super.key,
    required this.list,
  });

  final List<AssetPathEntity> list;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        final AssetPathEntity path = list[index];
        return ListTile(
          title: Text(path.name),
          subtitle: Text(path.id),
          trailing: FutureBuilder<int>(
            future: path.assetCountAsync,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data.toString());
              }
              return const SizedBox();
            },
          ),
          onTap: () {
            path.assetCountAsync.then((value) {
              showToast(
                'Asset count: $value',
                position: ToastPosition.bottom,
              );
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PathPage(path: path),
              ),
            );
          },
        );
      },
      itemCount: list.length,
    );
  }
}
