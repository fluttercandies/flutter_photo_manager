import 'package:flutter/material.dart';
import 'package:photo_manager_example/widget/theme_button.dart';

String _defaultBuilder(Widget w) {
  return w.toStringShort();
}

class NavColumn extends StatelessWidget {
  const NavColumn({
    super.key,
    required this.children,
    this.titleBuilder = _defaultBuilder,
  });

  final List<Widget> children;
  final String Function(Widget w) titleBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: <Widget>[
              for (final Widget item in children) buildItem(context, item),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, Widget item) {
    return ThemeButton(
      text: titleBuilder(item),
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => item),
        );
      },
    );
  }
}
