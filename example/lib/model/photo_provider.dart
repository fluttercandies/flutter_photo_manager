import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity> list = [];

  int type = 0;

  DateTime dt = DateTime.now();

  var hasAll = true;

  Map<AssetPathEntity, PathProvider> pathProviderMap = {};

  void changeType(int v) {
    this.type = v;
    notifyListeners();
  }

  void changeHasAll(bool value) {
    this.hasAll = value;
    notifyListeners();
  }

  void changeDateToNow() {
    this.dt = DateTime.now();
    notifyListeners();
  }

  void changeDate(DateTime pickDt) {
    this.dt = pickDt;
    notifyListeners();
  }

  void reset() {
    this.list.clear();
    pathProviderMap.clear();
  }

  Future<void> refreshGalleryList() async {
    var galleryList = await PhotoManager.getAssetPathList(
      fetchDateTime: dt,
      type: RequestType.values[type],
      hasAll: hasAll,
    );

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    this.list.addAll(galleryList);
  }

  PathProvider getOrCreatePathProvider(AssetPathEntity pathEntity) {
    pathProviderMap[pathEntity] ??= PathProvider(pathEntity);
    return pathProviderMap[pathEntity];
  }
}

class PathProvider extends ChangeNotifier {
  static const loadCount = 50;

  bool isInit = false;

  final AssetPathEntity path;
  PathProvider(this.path);

  List<AssetEntity> list = [];

  var page = 0;

  Future onRefresh() async {
    final list = await path.getAssetListPaged(0, loadCount);
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    isInit = true;
    notifyListeners();
  }

  Future<void> onLoadMore() async {
    final list = await path.getAssetListPaged(page + 1, loadCount);
    page = page + 1;
    this.list.addAll(list);
    notifyListeners();
  }

  void delete(AssetEntity entity) async {
    final result = await PhotoManager.deleteWithIds([entity.id]);
    if (result.isNotEmpty) {
      await path.refreshPathProperties(dt: path.fetchDatetime);
      final list =
          await path.getAssetListRange(start: 0, end: (page + 1) * loadCount);
      print("new list = ${list.length}");
      this.list.clear();
      this.list.addAll(list);
      notifyListeners();
    }
  }
}
