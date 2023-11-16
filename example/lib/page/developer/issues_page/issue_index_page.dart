import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager_example/widget/nav_column.dart';
import 'package:photo_manager_example/widget/theme_button.dart';
import 'package:url_launcher/url_launcher.dart';

import 'issue_1025.dart';
import 'issue_1031.dart';
import 'issue_734.dart';
import 'issue_918.dart';
import 'issue_962.dart';
import 'issue_979.dart';
import 'issue_988.dart';

class IssuePage extends StatelessWidget {
  const IssuePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue page list'),
      ),
      body: NavColumn(
        titleBuilder: (w) {
          if (w is StatefulWidget) {
            // ignore: invalid_use_of_protected_member
            final state = (w).createState();

            if (state is IssueBase) {
              final issueNumber = state.issueNumber;
              return 'Issue $issueNumber';
            }
          }
          return w.toStringShort();
        },
        children: const <Widget>[
          Issue734Page(),
          Issue918Page(),
          Issue962(),
          Issue1025Page(),
          Issue988(),
          Issue1031Page(),
          Issue979(),
        ],
      ),
    );
  }
}

mixin IssueBase<T extends StatefulWidget> on State<T> {
  int get issueNumber;

  String get issueUrl =>
      'https://github.com/fluttercandies/flutter_photo_manager/issues/$issueNumber';

  final List<String> _logs = [];

  void addLog(String log) {
    log = '[${DateTime.now().toIso8601String()}] $log';
    _logs.insert(0, log);
    if (mounted) {
      setState(() {});
    }
  }

  Widget buildLogWidget({bool expaned = true}) {
    final w = ListView.separated(
      itemBuilder: (_, index) {
        final log = _logs[index];
        return Text(log);
      },
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const Divider(),
    );

    if (expaned) {
      return Expanded(child: w);
    } else {
      return w;
    }
  }

  Widget buildUrlButton() {
    return IconButton(
      icon: const Icon(Icons.info),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: issueUrl));
        showToastWidget(Material(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'The issue of $issueNumber was been copied.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ));
      },
      tooltip: 'Copy issue url to clipboard.',
    );
  }

  Widget _buildOpenButton() {
    return IconButton(
      icon: const Icon(Icons.open_in_new),
      onPressed: () {
        launchUrl(Uri.parse(issueUrl));
      },
      tooltip: 'Copy issue url to clipboard.',
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      title: Text('$issueNumber issue page'),
      actions: <Widget>[
        _buildOpenButton(),
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
    return ThemeButton(
      onPressed: onTap,
      text: text,
    );
  }

  Widget buildScaffold(List<Widget> children) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(children),
    );
  }
}
