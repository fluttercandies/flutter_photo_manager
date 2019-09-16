import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity> list = [];

  int type = 0;

  DateTime dt = DateTime.now();

  var hasAll = true;

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
}

class PathProvider extends ChangeNotifier {}
