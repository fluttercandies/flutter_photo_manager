import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:provider/provider.dart';

class FilterOptionPage extends StatefulWidget {
  @override
  _FilterOptionPageState createState() => _FilterOptionPageState();
}

class _FilterOptionPageState extends State<FilterOptionPage> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Options.'),
      ),
      body: ListView(
        children: <Widget>[
          buildInput(provider.minWidth, "minWidth", (value) {
            provider.minWidth = value;
          }),
          buildInput(provider.maxWidth, "maxWidth", (value) {
            provider.maxWidth = value;
          }),
          buildInput(provider.minHeight, "minHeight", (value) {
            provider.minHeight = value;
          }),
          buildInput(provider.maxHeight, "maxHeight", (value) {
            provider.maxHeight = value;
          }),
          buildNeedTitleCheck(provider),
          buildDurationWidget(
            provider,
            "minDuration",
            provider.minDuration,
            (Duration duration) {
              provider.minDuration = duration;
            },
          ),
          buildDurationWidget(
            provider,
            "maxDuration",
            provider.maxDuration,
            (Duration duration) {
              provider.maxDuration = duration;
            },
          ),
        ],
      ),
    );
  }

  Widget buildInput(
    String initValue,
    String hintText,
    void onChanged(String value),
  ) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: EdgeInsets.all(8),
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
      builder: (context, snapshot) {
        return CheckboxListTile(
          title: Text('need title'),
          onChanged: (bool value) {
            provider.needTitle = value;
          },
          value: provider.needTitle,
        );
      },
    );
  }

  Widget buildDurationWidget(Listenable listenable, String title,
      Duration value, void Function(Duration duration) onChanged) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, snapshot) {
        return ListTile(
          title: Text(
              "${value.inHours.toString().padLeft(2, '0')}h : ${(value.inMinutes % 60).toString().padLeft(2, '0')}m"),
          onTap: () async {
            // final duration = await showDurationPicker(
            //   context: context,
            //   initialTime: value,
            //   snapToMins: 0.5,
            // );
            final timeOfDay =
                TimeOfDay(hour: value.inHours, minute: value.inMinutes);
            final result =
                await showTimePicker(context: context, initialTime: timeOfDay);
            if (result != null) {
              final duration =
                  Duration(hours: result.hour, minutes: result.minute);
              if (duration != null) {
                onChanged(duration);
              }
            }
          },
        );
      },
    );
  }
}
