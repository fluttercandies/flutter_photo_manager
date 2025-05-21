import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

import 'issue_index_page.dart';

/// 复现 issue 1271: iOS 和 Android 上 thumbnailDataWithSize 行为不一致
/// 问题：同样的图片，使用 thumbnailDataWithSize 获取缩略图时：
/// - Android 将最小边缩放到 200px（正确）
/// - iOS 将最大边缩放到 200px（错误）
class Issue1271DemoPage extends StatefulWidget {
  const Issue1271DemoPage({super.key});

  @override
  State<Issue1271DemoPage> createState() => _Issue1271DemoPageState();
}

class _Issue1271DemoPageState extends State<Issue1271DemoPage>
    with IssueBase<Issue1271DemoPage> {
  AssetEntity? _asset;
  Uint8List? _thumbData;
  int? _thumbWidth;
  int? _thumbHeight;
  int? _originWidth;
  int? _originHeight;
  String _platformName = '';

  @override
  int get issueNumber => 1271;

  @override
  Widget build(BuildContext context) {
    return buildScaffold([
      buildButton('测试缩略图尺寸', _testThumbnailSize),
      if (_asset != null) _buildResultWidget(),
      buildLogWidget(),
    ]);
  }

  Widget _buildResultWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('平台: $_platformName'),
        Text('原图尺寸: $_originWidth x $_originHeight'),
        if (_thumbWidth != null && _thumbHeight != null)
          Text('缩略图尺寸: $_thumbWidth x $_thumbHeight'),
        const SizedBox(height: 8),
        if (_thumbData != null)
          SizedBox(
            height: 150,
            child: Image.memory(_thumbData!),
          ),
        const SizedBox(height: 8),
        const Text('说明：'),
        const Text(
          '- 选择一张宽高比大于2:1的图片\n'
          '- 使用 thumbnailDataWithSize(ThumbnailSize(200, 200)) 获取缩略图\n'
          '- 预期：缩略图应保持原图宽高比，最小边为200\n'
          '- 实际：Android 最小边为200，iOS 最大边为200',
        ),
      ],
    );
  }

  Future<void> _testThumbnailSize() async {
    addLog('开始测试缩略图尺寸...');

    // 请求权限
    final pmResult = await PhotoManager.requestPermissionExtend();
    if (!pmResult.isAuth) {
      addLog('没有相册权限！');
      return;
    }

    // 获取相册列表
    addLog('获取相册列表...');
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (paths.isEmpty) {
      addLog('没有找到相册！');
      return;
    }

    // 获取第一个相册的图片
    addLog('获取相册图片...');
    final List<AssetEntity> assets = await paths[0].getAssetListPaged(
      page: 0,
      size: 20,
    );
    if (assets.isEmpty) {
      addLog('相册中没有图片！');
      return;
    }

    // 查找宽高比大于2的图片
    AssetEntity? targetAsset;
    for (final asset in assets) {
      final ratio = asset.width / asset.height;
      if (ratio > 2 || ratio < 0.5) {
        targetAsset = asset;
        addLog('找到宽高比例为 ${ratio.toStringAsFixed(2)} 的图片');
        break;
      }
    }

    // 如果没找到宽高比大于2的图片，就用第一张
    targetAsset ??= assets[0];
    final originWidth = targetAsset.width;
    final originHeight = targetAsset.height;
    addLog('选择图片: $originWidth x $originHeight');

    // 获取缩略图
    addLog('获取缩略图 ThumbnailSize(200, 200)...');
    final thumbData = await targetAsset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );

    if (thumbData == null) {
      addLog('获取缩略图失败！');
      return;
    }

    // 解码缩略图获取实际尺寸
    final decodedImage = img.decodeImage(thumbData);
    if (decodedImage == null) {
      addLog('解码缩略图失败！');
      return;
    }

    final thumbWidth = decodedImage.width;
    final thumbHeight = decodedImage.height;
    addLog('缩略图实际尺寸: $thumbWidth x $thumbHeight');

    // 计算缩放比例
    final widthRatio = thumbWidth / originWidth;
    final heightRatio = thumbHeight / originHeight;
    addLog('宽度缩放比例: ${widthRatio.toStringAsFixed(3)}');
    addLog('高度缩放比例: ${heightRatio.toStringAsFixed(3)}');

    // 判断是按最小边还是最大边缩放
    if (originWidth > originHeight) {
      // 横向图片
      if ((thumbHeight - 200).abs() < 5) {
        addLog('结论: 最小边(高)被缩放到接近200，符合预期');
      } else if ((thumbWidth - 200).abs() < 5) {
        addLog('结论: 最大边(宽)被缩放到接近200，不符合预期');
      }
    } else {
      // 纵向图片
      if ((thumbWidth - 200).abs() < 5) {
        addLog('结论: 最小边(宽)被缩放到接近200，符合预期');
      } else if ((thumbHeight - 200).abs() < 5) {
        addLog('结论: 最大边(高)被缩放到接近200，不符合预期');
      }
    }

    setState(() {
      _asset = targetAsset;
      _thumbData = thumbData;
      _originWidth = originWidth;
      _originHeight = originHeight;
      _thumbWidth = thumbWidth;
      _thumbHeight = thumbHeight;
      _platformName = Theme.of(context).platform.toString();
    });
  }
}
