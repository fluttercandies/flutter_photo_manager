import 'package:flutter/material.dart';

import 'change_notify_page.dart';
import 'developer/develop_index_page.dart';
import 'home_page.dart';
import 'save_image_example.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example for photo manager.'),
      ),
      body: ListView(
        children: <Widget>[
          routePage('gallery list', const NewHomePage()),
          routePage('save media example', const SaveMediaExample()),
          routePage('For Developer page', const DeveloperIndexPage()),
          routePage('Change notify example', const ChangeNotifyExample()),
        ],
      ),
    );
  }

  Widget routePage(String title, Widget page) {
    return ElevatedButton(
      onPressed: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      ),
      child: Text(title),
    );
  }
}
