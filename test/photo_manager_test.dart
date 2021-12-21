import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  test('RequestType equality test', () {
    expect(RequestType.image == RequestType(1), equals(true));
    expect(RequestType.video == RequestType(2), equals(true));
    expect(RequestType.audio == RequestType(4), equals(true));
    expect(RequestType.common == RequestType(3), equals(true));
    expect(RequestType.all == RequestType(7), equals(true));
  });
}
