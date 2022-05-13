import 'package:flutter/material.dart';

class ListDialog extends StatefulWidget {
  const ListDialog({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  State<ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<ListDialog> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: widget.children,
      ),
    );
  }
}
