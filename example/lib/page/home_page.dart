import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';
import '../widget/change_notifier_builder.dart';
import 'filter_option_page.dart';
import 'gallery_list_page.dart';

class NewHomePage extends StatefulWidget {
  const NewHomePage({Key? key}) : super(key: key);

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  PhotoProvider get readProvider => context.read<PhotoProvider>();

  PhotoProvider get watchProvider => context.watch<PhotoProvider>();

  @override
  void initState() {
    super.initState();
    PhotoManager.addChangeCallback(onChange);
    PhotoManager.setLog(true);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierBuilder<PhotoProvider>(
      value: watchProvider,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: const Text('photo manager example'),
        ),
        body: ListView(
          children: <Widget>[
            buildButton('Get all gallery list', _scanGalleryList),
            if (Platform.isIOS)
              buildButton(
                'Change limited photos with PhotosUI',
                _changeLimitPhotos,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('scan type'),
                Container(width: 10),
              ],
            ),
            _buildTypeChecks(watchProvider),
            _buildHasAllCheck(),
            _buildOnlyAllCheck(),
            _buildContainsLivePhotos(),
            _buildOnlyLivePhotos(),
            _buildContainsEmptyCheck(),
            _buildPathContainsModifiedDateCheck(),
            _buildPngCheck(),
            _buildNotifyCheck(),
            _buildFilterOption(watchProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChecks(PhotoProvider provider) {
    final RequestType currentType = provider.type;
    Widget buildType(RequestType type) {
      String typeText;
      if (type.containsImage()) {
        typeText = 'image';
      } else if (type.containsVideo()) {
        typeText = 'video';
      } else if (type.containsAudio()) {
        typeText = 'audio';
      } else {
        typeText = '';
      }

      return Expanded(
        child: CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          title: Text(typeText),
          value: currentType.containsType(type),
          onChanged: (bool? value) {
            if (value == true) {
              provider.changeType(currentType + type);
            } else {
              provider.changeType(currentType - type);
            }
          },
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: Row(
        children: <Widget>[
          buildType(RequestType.image),
          buildType(RequestType.video),
          buildType(RequestType.audio),
        ],
      ),
    );
  }

  Future<void> _scanGalleryList() async {
    await readProvider.refreshGalleryList();
    if (!mounted) {
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => const GalleryListPage(),
      ),
    );
  }

  Widget _buildHasAllCheck() {
    return CheckboxListTile(
      value: watchProvider.hasAll,
      onChanged: (bool? value) {
        readProvider.changeHasAll(value);
      },
      title: const Text('hasAll'),
    );
  }

  Widget _buildPngCheck() {
    return CheckboxListTile(
      value: watchProvider.thumbFormat == ThumbnailFormat.png,
      onChanged: (bool? value) {
        readProvider.changeThumbFormat();
      },
      title: const Text('thumb png'),
    );
  }

  Widget _buildOnlyAllCheck() {
    return CheckboxListTile(
      value: watchProvider.onlyAll,
      onChanged: (bool? value) {
        readProvider.changeOnlyAll(value);
      },
      title: const Text('onlyAll'),
    );
  }

  Widget _buildContainsLivePhotos() {
    if (Platform.isAndroid) {
      return Container();
    }
    return CheckboxListTile(
      value: watchProvider.containsLivePhotos,
      onChanged: (bool? value) {
        if (value != null) {
          readProvider.containsLivePhotos = value;
        }
      },
      title: const Text('Contains Live Photos'),
    );
  }

  Widget _buildOnlyLivePhotos() {
    if (Platform.isAndroid) {
      return Container();
    }
    return CheckboxListTile(
      value: watchProvider.onlyLivePhotos,
      onChanged: (bool? value) {
        if (value != null) {
          readProvider.onlyLivePhotos = value;
        }
      },
      title: const Text('Only Live Photos'),
    );
  }

  Widget _buildContainsEmptyCheck() {
    if (!Platform.isIOS) {
      return Container();
    }
    return CheckboxListTile(
      value: watchProvider.containsEmptyAlbum,
      onChanged: (bool? value) {
        readProvider.changeContainsEmptyAlbum(value);
      },
      title: const Text('contains empty album(only iOS)'),
    );
  }

  Widget _buildPathContainsModifiedDateCheck() {
    return CheckboxListTile(
      value: watchProvider.containsPathModified,
      onChanged: (bool? value) {
        readProvider.changeContainsPathModified(value);
      },
      title: const Text('contains path modified date'),
    );
  }

  Widget _buildNotifyCheck() {
    return CheckboxListTile(
        value: watchProvider.notifying,
        title: const Text('onChanged'),
        onChanged: (bool? value) {
          readProvider.notifying = value;
          if (value == true) {
            PhotoManager.startChangeNotify();
          } else {
            PhotoManager.stopChangeNotify();
          }
        });
  }

  void onChange(MethodCall call) {}

  Widget _buildFilterOption(PhotoProvider provider) {
    return ElevatedButton(
      child: const Text('Change filter options.'),
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const FilterOptionPage()),
        );
      },
    );
  }

  Future<void> _changeLimitPhotos() async {
    await PhotoManager.presentLimited();
  }
}

Widget buildButton(String text, VoidCallback function) {
  return ElevatedButton(
    onPressed: function,
    child: Text(text),
  );
}
