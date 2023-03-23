import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/page/custom_filter/path_page.dart';

class FilterPathList extends StatelessWidget {
  final CustomFilter filter;

  const FilterPathList({Key? key, required this.filter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetPathEntity>>(
      future: PhotoManager.getAssetPathList(
        filterOption: filter,
      ),
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
    Key? key,
    required this.list,
  }) : super(key: key);

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
