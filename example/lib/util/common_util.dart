// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import 'log.dart';

class CommonUtil {
  const CommonUtil._();

  static Future<void> showInfoDialog(
    BuildContext context,
    AssetEntity entity,
  ) async {
    final LatLng latlng = await entity.latlngAsync();

    final double? lat =
        entity.latitude == 0 ? latlng.latitude : entity.latitude;
    final double? lng =
        entity.longitude == 0 ? latlng.longitude : entity.longitude;

    final Widget w = Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(15),
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                child: _buildInfoItem('id', entity.id),
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: entity.id));
                  showToast('The id already copied.');
                },
              ),
              _buildInfoItem('create', entity.createDateTime.toString()),
              _buildInfoItem('modified', entity.modifiedDateTime.toString()),
              _buildInfoItem('orientation', entity.orientation.toString()),
              _buildInfoItem('size', entity.size.toString()),
              _buildInfoItem(
                'orientatedSize',
                entity.orientatedSize.toString(),
              ),
              _buildInfoItem('duration', entity.videoDuration.toString()),
              _buildInfoItemAsync('title', entity.titleAsync),
              _buildInfoItem('lat', lat.toString()),
              _buildInfoItem('lng', lng.toString()),
              _buildInfoItem('relative path', entity.relativePath ?? 'null'),
              _buildInfoItemAsync('mimeType', entity.mimeTypeAsync),
            ],
          ),
        ),
      ),
    );
    showDialog<void>(context: context, builder: (BuildContext c) => w);
  }

  static Widget _buildInfoItem(String title, String? info) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            width: 88,
            child: Text(title.padLeft(10)),
          ),
          Expanded(
            child: Text((info ?? 'null').padLeft(40)),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoItemAsync(String title, Future<String?> info) {
    return FutureBuilder<String?>(
      future: info,
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (!snapshot.hasData) {
          return _buildInfoItem(title, '');
        }
        return _buildInfoItem(title, snapshot.data);
      },
    );
  }
}

Future<T> elapsedFuture<T>(
  Future<T> future, {
  String? prefix,
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  final T result = await future;
  stopwatch.stop();
  Log.d('${prefix != null ? '$prefix: ' : ''}${stopwatch.elapsed}');
  return result;
}
