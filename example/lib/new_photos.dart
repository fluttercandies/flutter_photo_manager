import 'package:flutter/material.dart';

class NewPhotosPage extends StatefulWidget {
  @override
  _NewPhotosPageState createState() => _NewPhotosPageState();
}

class _NewPhotosPageState extends State<NewPhotosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('标题'),
      ),
      body: NotificationListener(
        onNotification: _handlerNotify,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
          ),
          itemBuilder: _buildItem,
          itemCount: 200,
        ),
      ),
    );
  }

  bool scrolling = false;

  Set<int> set = Set();

  Widget _buildItem(BuildContext context, int index) {
    if (scrolling && !set.contains(index)) {
      return Container(
        color: Colors.black38,
      );
    }
    set.add(index);
    return Center(
      child: Text('加载成功 $index'),
    );
  }

  bool _handlerNotify(Notification notification) {
    if (notification is ScrollStartNotification) {
      scrolling = true;
    }

    if (notification is ScrollEndNotification) {
      scrolling = false;
      setState(() {});
    }

    if (notification is ScrollUpdateNotification) {
      print(notification.dragDetails);
    }
    return false;
  }
}
