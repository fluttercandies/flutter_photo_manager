import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

import '../detail_page.dart';

class CreateEntityById extends StatefulWidget {
  const CreateEntityById({super.key});

  @override
  State<CreateEntityById> createState() => _CreateEntityByIdState();
}

class _CreateEntityByIdState extends State<CreateEntityById> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = '1016711';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create AssetEntity by id'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'input asset id',
              ),
            ),
            ElevatedButton(
              onPressed: createAssetEntityAndShow,
              child: const Text('Create assetEntity'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createAssetEntityAndShow() async {
    final String id = controller.text.trim();
    final AssetEntity? asset = await AssetEntity.fromId(id);
    if (asset == null) {
      showToast('Cannot create asset by $id');
      return;
    }

    if (!mounted) {
      return;
    }
    return Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext c) => DetailPage(entity: asset),
      ),
    );
  }
}
