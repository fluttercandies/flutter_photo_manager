import 'package:flutter/material.dart';

class ListDialog extends StatefulWidget {
  const ListDialog({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  State<ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<ListDialog> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        padding: widget.padding,
        shrinkWrap: true,
        children: widget.children,
      ),
    );
  }
}
