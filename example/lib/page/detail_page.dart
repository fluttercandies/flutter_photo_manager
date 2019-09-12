import 'dart:io';

import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final File file;

  const DetailPage({Key key, this.file}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    return Image.file(widget.file);
  }
}
