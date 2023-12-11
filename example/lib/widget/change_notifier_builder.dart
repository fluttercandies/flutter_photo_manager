import 'package:flutter/material.dart';

typedef ChangeNotifierWidgetBuilder<T extends ChangeNotifier> = Widget Function(
  BuildContext context,
  T value,
);

class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ChangeNotifierBuilder({
    super.key,
    required this.builder,
    required this.value,
  });

  final ChangeNotifierWidgetBuilder<T> builder;
  final T value;

  @override
  State<ChangeNotifierBuilder<T>> createState() =>
      _ChangeNotifierBuilderState<T>();
}

class _ChangeNotifierBuilderState<T extends ChangeNotifier>
    extends State<ChangeNotifierBuilder<T>> {
  @override
  void initState() {
    super.initState();
    widget.value.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.value.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.value);
  }
}
