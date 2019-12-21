import 'package:flutter/material.dart';
import 'package:image_scanner_example/page/home_page.dart';

import 'save_image_example.dart';

class IndexPage extends StatefulWidget {
  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Example for photo manager."),
      ),
      body: Column(
        children: <Widget>[
          routePage("gallery list", NewHomePage()),
          routePage("insert image", SaveImageExample()),
        ],
      ),
    );
  }

  Widget routePage(String title, Widget page) {
    return RaisedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return page;
            },
          ),
        );
      },
      child: Text(title),
    );
  }
}
