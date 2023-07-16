import 'package:flutter/material.dart';
import 'package:photo_manager_example/widget/theme_button.dart';

class NavColumn extends StatelessWidget {
  const NavColumn({
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
    return ThemeButton(
      text: item.toStringShort(),
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => item),
        );
      },
    );
  }
}
