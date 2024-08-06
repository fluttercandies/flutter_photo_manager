import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../util/log_export.dart';

class VerboseLogPage extends StatefulWidget {
  const VerboseLogPage({super.key});

  @override
  State<VerboseLogPage> createState() => _VerboseLogPageState();
}

class _VerboseLogPageState extends State<VerboseLogPage> {
  final List<String> _logList = <String>[];

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    final logFilePath = await PMVerboseLogUtil.shared.getLogFilePath();
    final file = File(logFilePath);
    if (!file.existsSync()) {
      _logList.clear();
      setState(() {});
      return;
    }
    final lines = file.readAsLinesSync();
    _logList.clear();
    setState(() {
      _logList.addAll(lines);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevVerboseLogPage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final logFilePath =
                  await PMVerboseLogUtil.shared.getLogFilePath();
              final file = File(logFilePath);
              if (file.existsSync()) {
                file.deleteSync();
              }
              _loadLog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadLog();
            },
          ),
          // 复制日志
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final log = _logList.join('\n');
              Clipboard.setData(ClipboardData(text: log));
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return Text(_logList[index], maxLines: 1);
        },
        itemCount: _logList.length,
      ),
    );
  }
}
