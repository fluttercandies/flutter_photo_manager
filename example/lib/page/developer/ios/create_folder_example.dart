import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class CreateFolderExample extends StatefulWidget {
  const CreateFolderExample({super.key});

  @override
  State<CreateFolderExample> createState() => _CreateFolderExampleState();
}

class _CreateFolderExampleState extends State<CreateFolderExample> {
  final TextEditingController nameController = TextEditingController();

  List<AssetPathEntity> subDir = <AssetPathEntity>[];

  AssetPathEntity? parent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create folder')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: nameController,
            ),
            Row(
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: createFolder,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Create folder'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton.icon(
                  onPressed: createAlbum,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Create album'),
                ),
              ],
            ),
            _buildParentTarget(),
            ElevatedButton.icon(
              onPressed: () async {
                final AssetPathEntity path =
                    (await PhotoManager.getAssetPathList(onlyAll: true))[0];
                final List<AssetPathEntity> subPath =
                    await path.getSubPathList();
                subDir = subPath;
                parent = null;
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh sub path'),
            ),
          ],
        ),
      ),
    );
  }

  void createFolder() {
    final String name = nameController.text;
    PhotoManager.editor.darwin.createFolder(
      name,
      parent: parent,
    );
  }

  void createAlbum() {
    final String name = nameController.text;
    PhotoManager.editor.darwin.createAlbum(
      name,
      parent: parent,
    );
  }

  Widget _buildParentTarget() {
    return DropdownButton<AssetPathEntity>(
      items: subDir
          .map<DropdownMenuItem<AssetPathEntity>>(
            (AssetPathEntity v) => _buildItem(v),
          )
          .toList(),
      onChanged: (AssetPathEntity? path) {
        parent = path;
        setState(() {});
      },
      value: parent,
      hint: const Text('Select parent path.'),
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity pathEntity) {
    return DropdownMenuItem<AssetPathEntity>(
      value: pathEntity,
      child: Text(pathEntity.name),
    );
  }
}
