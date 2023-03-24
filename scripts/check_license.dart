// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:io';

const _license =
    '''// Copyright 2018 The FlutterCandies author. All rights reserved.
// Use of this source code is governed by an Apache license that can be found
// in the LICENSE file.''';

void main(List<String> args) {
  final dir = Directory(args[0]);

  final dartFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  final unlicensedFiles = <File>[];

  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    final checkLines = lines.sublist(0, 3);

    if (checkLines.join('\n') != _license) {
      unlicensedFiles.add(file);
    }
  }

  if (unlicensedFiles.isNotEmpty) {
    print('The following files are missing the license header:');
    for (final file in unlicensedFiles) {
      print(file.path);
    }
    exit(1);
  }
}
