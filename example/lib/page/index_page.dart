import 'package:flutter/material.dart';
import 'package:photo_manager_example/page/custom_filter_example_page.dart';
import 'package:photo_manager_example/widget/nav_button.dart';

import 'change_notify_page.dart';
import 'developer/develop_index_page.dart';
import 'home_page.dart';
import 'save_image_example.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

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
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          routePage('Gallery list', const NewHomePage()),
          routePage('Custom filter example', const CustomFilterExamplePage()),
          routePage('Save media example', const SaveMediaExample()),
          routePage('Change notify example', const ChangeNotifyExample()),
          routePage('For Developer page', const DeveloperIndexPage()),
        ],
      ),
    );
  }

  Widget routePage(String title, Widget page) {
    return NavButton(title: title, page: page);
  }
}
