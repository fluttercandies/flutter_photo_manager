import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/page/home_page.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

final provider = PhotoProvider();

void main() => runApp(
      OKToast(
        child: ChangeNotifierProvider<PhotoProvider>.value(
          value: provider,
          child: MaterialApp(
            home: NewHomePage(),
          ),
        ),
      ),
    );
