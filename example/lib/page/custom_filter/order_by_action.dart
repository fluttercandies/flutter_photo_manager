import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class OrderByAction extends StatefulWidget {
  const OrderByAction({
    Key? key,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  final List<OrderByItem> items;
  final ValueChanged<List<OrderByItem>> onChanged;

  @override
  State<OrderByAction> createState() => _OrderByActionState();
}

class _OrderByActionState extends State<OrderByAction> {
  List<OrderByItem> _orderBy = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class OrderByActionPage extends StatefulWidget {
  const OrderByActionPage({Key? key}) : super(key: key);

  @override
  State<OrderByActionPage> createState() => _OrderByActionPageState();
}

class _OrderByActionPageState extends State<OrderByActionPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
