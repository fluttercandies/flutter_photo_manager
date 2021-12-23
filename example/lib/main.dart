import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

import 'model/photo_provider.dart';
import 'page/index_page.dart';

final PhotoProvider provider = PhotoProvider();

void main() {
  runApp(
    OKToast(
      child: ChangeNotifierProvider<PhotoProvider>.value(
        value: provider,
        child: const MaterialApp(home: IndexPage()),
      ),
    ),
  );
}
