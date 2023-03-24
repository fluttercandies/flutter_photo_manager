import 'dart:convert';

import '../../photo_manager.dart';

// {
//   "timeRange": {
//     "startTime": 0.0,
//     "duration": 40.18666666666667
//   },
//   "mediaType": "vide",
//   "nominalFrameRate": 47.81670379638672,
//   "segments": [
//     {
//       "target": {
//         "start": 0.0,
//         "duration": 40.18666666666667
//       },
//       "source": {
//         "start": 2.033333333333333,
//         "duration": 40.18666666666667
//       }
//     }
//   ]
// }

class CMTimeRange with IMappable {
  final double startTime;
  final double duration;

  CMTimeRange({
    required this.startTime,
    required this.duration,
  });

  factory CMTimeRange.fromJson(Map json) {
    return CMTimeRange(
      startTime: json['startTime'] as double,
      duration: json['duration'] as double,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'duration': duration,
    };
  }
}

class AVAssetTrackSegment with IMappable {
  final CMTimeRange source;
  final CMTimeRange target;

  AVAssetTrackSegment({
    required this.source,
    required this.target,
  });

  factory AVAssetTrackSegment.fromJson(Map json) {
    return AVAssetTrackSegment(
      source: CMTimeRange.fromJson(json['source']),
      target: CMTimeRange.fromJson(json['target']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'source': source.toMap(),
      'target': target.toMap(),
    };
  }
}

class AVAssetTrackMeta with IMappable {
  final String mediaType;
  final CMTimeRange timeRange;
  final double nominalFrameRate;
  final List<AVAssetTrackSegment> segments;

  AVAssetTrackMeta({
    required this.mediaType,
    required this.timeRange,
    required this.nominalFrameRate,
    required this.segments,
  });

  factory AVAssetTrackMeta.fromJson(Map json) {
    print(JsonEncoder.withIndent('  ').convert(json));
    return AVAssetTrackMeta(
      mediaType: json['mediaType'] as String,
      timeRange: CMTimeRange.fromJson(json['timeRange']),
      nominalFrameRate: json['nominalFrameRate'] as double,
      segments: (json['segments'] as List)
          .map((e) => AVAssetTrackSegment.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'mediaType': mediaType,
      'timeRange': timeRange.toMap(),
      'nominalFrameRate': nominalFrameRate,
      'segments': segments.map((e) => e.toMap()).toList(),
    };
  }
}
