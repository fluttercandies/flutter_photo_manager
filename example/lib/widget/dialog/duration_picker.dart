import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DurationPicker extends StatefulWidget {
  final Duration initDuration;

  const DurationPicker({
    Key key,
    this.initDuration,
  }) : super(key: key);

  @override
  _DurationPickerState createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  int hours;
  int minutes;
  int seconds;

  @override
  void initState() {
    super.initState();

    final duration = widget.initDuration;
    hours = duration.inMicroseconds ~/ Duration.microsecondsPerHour;
    minutes = duration.inMicroseconds ~/ Duration.microsecondsPerMinute % 60;
    seconds = duration.inMicroseconds ~/ Duration.microsecondsPerSecond % 60;

    print(hours);
    print(minutes);
    print(seconds);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: RaisedButton(
                  padding: const EdgeInsets.all(0),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    Navigator.pop(
                      context,
                      Duration(
                          hours: hours, minutes: minutes, seconds: seconds),
                    );
                  },
                  child: Text(
                    "Sure",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
            Material(
              child: Container(
                height: 88,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildPicker(
                      title: "h",
                      currentValue: hours,
                      max: 23,
                      valueChanged: (int value) {
                        hours = value;
                        changeDuration();
                      },
                    ),
                    _buildPicker(
                        title: "min",
                        currentValue: minutes,
                        max: 59,
                        valueChanged: (int value) {
                          minutes = value;
                          changeDuration();
                        }),
                    _buildPicker(
                        title: "sec",
                        currentValue: seconds,
                        max: 59,
                        valueChanged: (value) {
                          seconds = value;
                          changeDuration();
                        }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void changeDuration() {
    setState(() {});
  }

  Widget _buildPicker({
    String title,
    int currentValue,
    int max,
    ValueChanged<int> valueChanged,
  }) {
    return Expanded(
        child: Stack(
      children: <Widget>[
        CupertinoPicker.builder(
          scrollController:
              FixedExtentScrollController(initialItem: currentValue),
          itemExtent: 88,
          childCount: max + 1,
          onSelectedItemChanged: (value) {
            valueChanged(value);
          },
          itemBuilder: (context, index) {
            return Center(
              child: Text(index.toString()),
            );
          },
        ),
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 50.0),
              child: Text(title),
            ),
          ),
        ),
      ],
    ));
  }
}

Future<Duration> showCupertinoDurationPicker({
  @required BuildContext context,
  @required Duration initDuration,
}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return DurationPicker(
        initDuration: initDuration,
      );
    },
  );
}
