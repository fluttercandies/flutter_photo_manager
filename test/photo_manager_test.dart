// ignore_for_file: use_named_constants
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  test('RequestType equality test', () {
    expect(RequestType.image == const RequestType(1), equals(true));
    expect(RequestType.video == const RequestType(2), equals(true));
    expect(RequestType.audio == const RequestType(4), equals(true));
    expect(RequestType.common == const RequestType(3), equals(true));
    expect(RequestType.all == const RequestType(7), equals(true));
  });
}
