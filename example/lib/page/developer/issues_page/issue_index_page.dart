import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';

import 'issue_734.dart';

class IssuePage extends StatelessWidget {
  const IssuePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue page'),
      ),
      body: const _NavColumn(
        children: <Widget>[
          Issue734Page(),
        ],
      ),
    );
  }
}

class _NavColumn extends StatelessWidget {
  const _NavColumn({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          children: <Widget>[
            for (final Widget item in children) buildItem(context, item),
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, Widget item) {
    return ElevatedButton(
      child: Text(item.toString()),
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => item),
        );
      },
    );
  }
}

mixin IssueBase<T extends StatefulWidget> on State<T> {
  int get issueNumber;

  Widget buildUrlButton() {
    return IconButton(
      icon: const Icon(Icons.info),
      onPressed: () {
        final String issueUrl =
            'https://github.com/fluttercandies/flutter_photo_manager/issues/$issueNumber';

        Clipboard.setData(ClipboardData(text: issueUrl));

        showToast('The issue of $issueNumber was been copied.');
      },
      tooltip: 'Copy issue url to clipboard.',
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      title: Text('$issueNumber issue page'),
      actions: <Widget>[
        buildUrlButton(),
      ],
    );
  }

  Widget buildBody(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(text),
    );
  }
}
