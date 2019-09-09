import 'package:flutter/material.dart';
import 'package:image_scanner_example/page/home_page.dart';
import 'package:oktoast/oktoast.dart';

void main() => runApp(
      OKToast(
        child: MaterialApp(
          home: NewHomePage(),
        ),
      ),
    );
