import 'package:flutter/foundation.dart';
import 'package:image_scanner_example/main.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity> list = [];

  RequestType type = RequestType.common;

  var hasAll = true;

  var onlyAll = false;

  Map<AssetPathEntity, AssetPathProvider> pathProviderMap = {};

  bool _notifying = false;

  bool _needTitle = false;

  bool get needTitle => _needTitle;

  set needTitle(bool needTitle) {
    _needTitle = needTitle;
    notifyListeners();
  }

  DateTime _startDt = DateTime.now()
      .subtract(Duration(days: 365 * 8)); // Default Before 8 years

  DateTime get startDt => _startDt;

  set startDt(DateTime startDt) {
    _startDt = startDt;
    notifyListeners();
  }

  DateTime _endDt = DateTime.now();

  DateTime get endDt => _endDt;

  set endDt(DateTime endDt) {
    _endDt = endDt;
    notifyListeners();
  }

  bool _asc = false;

  bool get asc => _asc;

  set asc(bool asc) {
    _asc = asc;
    notifyListeners();
  }

  var _thumbFormat = ThumbFormat.png;

  ThumbFormat get thumbFormat => _thumbFormat;

  set thumbFormat(thumbFormat) {
    _thumbFormat = thumbFormat;
    notifyListeners();
  }

  bool get notifying => _notifying;

  String minWidth = "0";
  String maxWidth = "10000";
  String minHeight = "0";
  String maxHeight = "10000";
  bool _ignoreSize = false;

  bool get ignoreSize => _ignoreSize;

  set ignoreSize(bool ignoreSize) {
    _ignoreSize = ignoreSize;
    notifyListeners();
  }

  Duration _minDuration = Duration.zero;

  Duration get minDuration => _minDuration;

  set minDuration(Duration minDuration) {
    _minDuration = minDuration;
    notifyListeners();
  }

  Duration _maxDuration = Duration(hours: 1);

  Duration get maxDuration => _maxDuration;

  set maxDuration(Duration maxDuration) {
    _maxDuration = maxDuration;
    notifyListeners();
  }

  set notifying(bool notifying) {
    _notifying = notifying;
    notifyListeners();
  }

  void changeType(RequestType type) {
    this.type = type;
    notifyListeners();
  }

  void changeHasAll(bool value) {
    this.hasAll = value;
    notifyListeners();
  }

  void changeOnlyAll(bool value) {
    this.onlyAll = value;
    notifyListeners();
  }

  void reset() {
    this.list.clear();
    pathProviderMap.clear();
  }

  Future<void> refreshGalleryList() async {
    final option = makeOption();

    if (option == null) {
      assert(option != null);
      return;
    }

    reset();
    var galleryList = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: hasAll,
      onlyAll: onlyAll,
      filterOption: option,
    );

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    this.list.clear();
    this.list.addAll(galleryList);
  }

  AssetPathProvider getOrCreatePathProvider(AssetPathEntity pathEntity) {
    pathProviderMap[pathEntity] ??= AssetPathProvider(pathEntity);
    return pathProviderMap[pathEntity];
  }

  FilterOptionGroup makeOption() {
    SizeConstraint sizeConstraint;
    try {
      final minW = int.tryParse(minWidth);
      final maxW = int.tryParse(maxWidth);
      final minH = int.tryParse(minHeight);
      final maxH = int.tryParse(maxHeight);
      sizeConstraint = SizeConstraint(
        minWidth: minW,
        maxWidth: maxW,
        minHeight: minH,
        maxHeight: maxH,
        ignoreSize: ignoreSize,
      );
    } catch (e) {
      showToast("Cannot convert your size.");
      return null;
    }

    DurationConstraint durationConstraint = DurationConstraint(
      min: minDuration,
      max: maxDuration,
    );

    final option = FilterOption(
      sizeConstraint: sizeConstraint,
      durationConstraint: durationConstraint,
      needTitle: needTitle,
    );

    final dtCond = DateTimeCond(
      min: startDt,
      max: endDt,
      asc: asc,
    );

    return FilterOptionGroup()
      ..setOption(AssetType.video, option)
      ..setOption(AssetType.image, option)
      ..setOption(AssetType.audio, option)
      ..dateTimeCond = dtCond;
  }

  Future<void> refreshAllGalleryProperties() async {
    for (var gallery in list) {
      await gallery.refreshPathProperties();
    }
    notifyListeners();
  }

  void changeThumbFormat() {
    if (thumbFormat == ThumbFormat.jpeg) {
      thumbFormat = ThumbFormat.png;
    } else {
      thumbFormat = ThumbFormat.jpeg;
    }
  }
}

class AssetPathProvider extends ChangeNotifier {
  static const loadCount = 50;

  bool isInit = false;

  final AssetPathEntity path;
  AssetPathProvider(this.path);

  List<AssetEntity> list = [];

  var page = 0;

  int get showItemCount {
    if (list.length == path.assetCount) {
      return path.assetCount;
    } else {
      return path.assetCount;
    }
  }

  Future onRefresh() async {
    await path.refreshPathProperties();
    final list = await path.getAssetListPaged(0, loadCount);
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    isInit = true;
    notifyListeners();
    printListLength("onRefresh");
  }

  Future<void> onLoadMore() async {
    if (showItemCount > path.assetCount) {
      print("already max");
      return;
    }
    final list = await path.getAssetListPaged(page + 1, loadCount);
    page = page + 1;
    this.list.addAll(list);
    notifyListeners();
    printListLength("loadmore");
  }

  void delete(AssetEntity entity) async {
    final result = await PhotoManager.editor.deleteWithIds([entity.id]);
    if (result.isNotEmpty) {
      final rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final list = await path.getAssetListRange(start: 0, end: rangeEnd);
      this.list.clear();
      this.list.addAll(list);
      printListLength("deleted");
    }
  }

  void deleteSelectedAssets(List<AssetEntity> entity) async {
    final ids = entity.map((e) => e.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
  }

  void removeInAlbum(AssetEntity entity) async {
    if (await PhotoManager.editor.iOS.removeInAlbum(entity, path)) {
      final rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final list = await path.getAssetListRange(start: 0, end: rangeEnd);
      this.list.clear();
      this.list.addAll(list);
      printListLength("removeInAlbum");
    }
  }

  void printListLength(String tag) {
    print("$tag length : ${list.length}");
  }
}
