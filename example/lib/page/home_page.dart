import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/widget/nav_button.dart';
import 'package:provider/provider.dart';

import '../model/photo_provider.dart';
import '../widget/change_notifier_builder.dart';
import 'filter_option_page.dart';
import 'gallery_list_page.dart';

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});

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
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            CustomButton(
              title: 'Get all gallery list',
              onPressed: _scanGalleryList,
            ),
            if (Platform.isIOS || Platform.isAndroid)
              CustomButton(
                title: 'Change limited photos with PhotosUI',
                onPressed: _changeLimitPhotos,
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
            _buildPathContainsModifiedDateCheck(),
            _buildPngCheck(),
            _buildNotifyCheck(),
            _buildFilterOption(watchProvider),
            if (Platform.isIOS || Platform.isMacOS) _buildPathFilterOption(),
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
    final permissionResult = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: readProvider.type,
          mediaLocation: true,
        ),
      ),
    );
    if (!permissionResult.hasAccess) {
      showToast('no permission');
      return;
    }

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
        if (value == true) {
          PhotoManager.startChangeNotify();
        } else {
          PhotoManager.stopChangeNotify();
        }
        readProvider.notifying = value;
      },
    );
  }

  void onChange(MethodCall call) {}

  Widget _buildFilterOption(PhotoProvider provider) {
    return CustomButton(
      title: 'Change filter options.',
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const FilterOptionPage()),
        );
      },
    );
  }

  Widget _buildPathFilterOption() {
    return CustomButton(
      title: 'Change path filter options.',
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const DarwinPathFilterPage()),
        );
      },
    );
  }

  Future<void> _changeLimitPhotos() async {
    await PhotoManager.presentLimited();
  }
}
