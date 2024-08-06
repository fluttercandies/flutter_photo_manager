import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../util/log_export.dart';

class VerboseLogPage extends StatefulWidget {
  const VerboseLogPage({super.key});

  @override
  State<VerboseLogPage> createState() => _VerboseLogPageState();
}

class _LogUnit {
  _LogUnit({required this.log});

  final String log;

  bool get isResultLog => log.contains('- result -');

  bool get isInvokeLog => log.contains('- invoke -');

  int? get swTime {
    final reg = RegExp(r'Time: (\d+)ms');
    final match = reg.firstMatch(log);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return null;
  }
}

class _VerboseLogPageState extends State<VerboseLogPage> {
  final List<_LogUnit> logList = <_LogUnit>[];

  final List<String> originList = <String>[];

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  List<_LogUnit> decodeUnit(String text) {
    final List<_LogUnit> list = <_LogUnit>[];
    final List<String> items = text.split('===');
    for (final String item in items) {
      list.add(_LogUnit(log: item.trim()));
    }
    return list;
  }

  Future<void> _loadLog() async {
    final logFilePath = await PMVerboseLogUtil.shared.getLogFilePath();
    final file = File(logFilePath);
    if (!file.existsSync()) {
      logList.clear();
      setState(() {});
      return;
    }
    final content = file.readAsStringSync();
    logList.clear();
    setState(() {
      logList.addAll(decodeUnit(content));
    });
  }

  Widget content(String text) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Text(
            line,
            maxLines: 1,
          ),
      ],
    );
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
              final content = logList.map((e) => e.log).join('\n');
              Clipboard.setData(ClipboardData(text: content));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilter(),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final item = logList[index];
                return ListTile(
                  title: content(item.log),
                  tileColor: item.isResultLog
                      ? Colors.green.withOpacity(0.1)
                      : item.isInvokeLog
                          ? Colors.blue.withOpacity(0.1)
                          : null,
                  subtitle: item.swTime != null
                      ? Text('Time: ${item.swTime}ms')
                      : null,
                );
              },
              itemCount: logList.length,
              separatorBuilder: (context, index) => const Divider(
                height: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Container();
  }
}
