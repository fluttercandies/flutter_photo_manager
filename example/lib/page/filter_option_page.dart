import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';
import '../widget/dialog/duration_picker.dart';

class FilterOptionPage extends StatefulWidget {
  const FilterOptionPage({super.key});

  @override
  State<FilterOptionPage> createState() => _FilterOptionPageState();
}

class _FilterOptionPageState extends State<FilterOptionPage> {
  @override
  Widget build(BuildContext context) {
    final PhotoProvider provider = context.watch<PhotoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Filter Options.')),
      body: ListView(
        children: <Widget>[
          buildInput(provider.minWidth, 'minWidth', (String value) {
            provider.minWidth = value;
          }),
          buildInput(provider.maxWidth, 'maxWidth', (String value) {
            provider.maxWidth = value;
          }),
          buildInput(provider.minHeight, 'minHeight', (String value) {
            provider.minHeight = value;
          }),
          buildInput(provider.maxHeight, 'maxHeight', (String value) {
            provider.maxHeight = value;
          }),
          buildIgnoreSize(provider),
          buildNeedTitleCheck(provider),
          buildDurationWidget(
            provider,
            'minDuration',
            provider.minDuration,
            (Duration duration) {
              provider.minDuration = duration;
            },
          ),
          buildDurationWidget(
            provider,
            'maxDuration',
            provider.maxDuration,
            (Duration duration) {
              provider.maxDuration = duration;
            },
          ),
          buildDateTimeWidget(
            provider,
            'Start DateTime',
            provider.startDt,
            (DateTime dateTime) {
              provider.startDt = dateTime;
            },
          ),
          buildDateTimeWidget(
            provider,
            'End DateTime',
            provider.endDt,
            (DateTime dateTime) {
              if (provider.startDt.difference(dateTime) < Duration.zero) {
                provider.endDt = dateTime;
              }
            },
          ),
          buildDateAscCheck(provider),
        ],
      ),
    );
  }

  Widget buildInput(
    String initValue,
    String hintText,
    void Function(String value) onChanged,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: const EdgeInsets.all(8),
        labelText: hintText,
      ),
      onChanged: onChanged,
      initialValue: initValue,
      keyboardType: TextInputType.number,
    );
  }

  Widget buildNeedTitleCheck(PhotoProvider provider) {
    return AnimatedBuilder(
      animation: provider,
      builder: (BuildContext context, Widget? snapshot) {
        return CheckboxListTile(
          title: const Text('need title'),
          onChanged: (bool? value) {
            provider.needTitle = value;
          },
          value: provider.needTitle,
        );
      },
    );
  }

  Widget buildIgnoreSize(PhotoProvider provider) {
    return AnimatedBuilder(
      animation: provider,
      builder: (BuildContext context, Widget? snapshot) {
        return CheckboxListTile(
          title: const Text('Ignore size with image'),
          onChanged: (bool? value) {
            provider.ignoreSize = value;
          },
          value: provider.ignoreSize,
        );
      },
    );
  }

  Widget buildDurationWidget(
    Listenable listenable,
    String title,
    Duration value,
    void Function(Duration duration) onChanged,
  ) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (BuildContext context, Widget? snapshot) {
        return ListTile(
          title: Text(title),
          subtitle: Text(
            "${value.inHours.toString().padLeft(2, '0')}h"
            ' : '
            "${(value.inMinutes % 60).toString().padLeft(2, '0')}m"
            ' : '
            "${(value.inSeconds % 60).toString().padLeft(2, '0')}s",
          ),
          onTap: () async {
            final Duration? duration = await showCupertinoDurationPicker(
              context: context,
              initDuration: value,
            );

            if (duration != null) {
              onChanged(duration);
            }
            // final timeOfDay =
            //     TimeOfDay(hour: value.inHours, minute: value.inMinutes);
            // final result =
            //     await showTimePicker(context: context, initialTime: timeOfDay);
            // if (result != null) {
            //   final duration =
            //       Duration(hours: result.hour, minutes: result.minute);
            //   if (duration != null) {
            //     onChanged(duration);
            //   }
            // }
          },
        );
      },
    );
  }

  Widget buildDateTimeWidget(
    PhotoProvider provider,
    String title,
    DateTime startDt,
    void Function(DateTime dateTime) onChange,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text('$startDt'),
      onTap: () async {
        final DateTime? result = await showDatePicker(
          context: context,
          initialDate: startDt,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );

        if (result != null) {
          onChange(result);
        }
      },
      trailing: ElevatedButton(
        child: const Text('Today'),
        onPressed: () {
          onChange(DateTime.now());
        },
      ),
    );
  }

  Widget buildDateAscCheck(PhotoProvider provider) {
    return CheckboxListTile(
      title: const Text('Date sort asc'),
      value: provider.asc,
      onChanged: (bool? value) {
        provider.asc = value;
      },
    );
  }
}

class DarwinPathFilterPage extends StatefulWidget {
  const DarwinPathFilterPage({super.key});

  @override
  State<DarwinPathFilterPage> createState() => _DarwinPathFilterPageState();
}

class _DarwinPathFilterPageState extends State<DarwinPathFilterPage> {
  Widget buildGroup<T>(
    String title,
    List<T> allValues,
    List<T> checkedValues,
    void Function(List<T> value) onChanged,
  ) {
    final List<T> currentValues = checkedValues.toList();
    return ExpansionTile(
      title: Text(title),
      children: allValues.map((T value) {
        return CheckboxListTile(
          title: Text(value.toString().split('.')[1]),
          value: currentValues.contains(value),
          onChanged: (bool? checked) {
            if (checked == true) {
              currentValues.add(value);
            } else {
              currentValues.remove(value);
            }
            onChanged(currentValues);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PhotoProvider provider = context.watch<PhotoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Path filter'),
      ),
      body: ListView(
        children: <Widget>[
          buildGroup<PMDarwinAssetCollectionType>(
            'PMDarwinAssetCollectionType',
            PMDarwinAssetCollectionType.values,
            provider.pathTypeList,
            (value) {
              provider.pathTypeList = value;
            },
          ),
          buildGroup<PMDarwinAssetCollectionSubtype>(
            'PMDarwinAssetCollectionSubtype',
            PMDarwinAssetCollectionSubtype.values,
            provider.pathSubTypeList,
            (value) {
              provider.pathSubTypeList = value;
            },
          ),
        ],
      ),
    );
  }
}
