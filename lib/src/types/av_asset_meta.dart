import 'types.dart';

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

/// {@template cm_time_range}
/// A range of time defined by a start time and a duration.
///
/// This class is used to represent a time range, which consists of a start time
/// (measured in seconds) and a duration (also measured in seconds).
/// {@endtemplate}
class CMTimeRange with IMappable {
  /// The start time of the time range, specified in seconds.
  final double startTime;

  /// The duration of the time range, specified in seconds.
  final double duration;

  /// {@macro cm_time_range}
  ///
  /// Creates a new `CMTimeRange` instance with the given `startTime` and `duration`.
  ///
  /// Both parameters are required and must be non-null.
  CMTimeRange({
    required this.startTime,
    required this.duration,
  });

  /// {@macro cm_time_range}
  ///
  /// Creates a new `CMTimeRange` instance from a JSON map.
  ///
  /// The map should contain the keys `startTime` and `duration`, which correspond
  /// to the `startTime` and `duration` properties of the `CMTimeRange` class.
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

/// {@template av_asset_track_segment}
/// A segment of an `AVAssetTrack`, defined by a source and target `CMTimeRange`.
///
/// This class is used to represent a segment of an `AVAssetTrack`, which consists
/// of a source `CMTimeRange` and a target `CMTimeRange`. The source `CMTimeRange`
/// represents the time range in the original asset from which the segment was extracted,
/// while the target `CMTimeRange` represents the corresponding time range in the new asset.
/// {@endtemplate}
class AVAssetTrackSegment with IMappable {
  /// The source `CMTimeRange` of the segment.
  final CMTimeRange source;

  /// The target `CMTimeRange` of the segment.
  final CMTimeRange target;

  /// {@macro av_asset_track_segment}
  ///
  /// Creates a new `AVAssetTrackSegment` instance with the given `source` and `target`.
  ///
  /// Both parameters are required and must be non-null.
  AVAssetTrackSegment({
    required this.source,
    required this.target,
  });

  /// {@macro av_asset_track_segment}
  ///
  /// Creates a new `AVAssetTrackSegment` instance from a JSON map.
  ///
  /// The map should contain the keys `source` and `target`, which correspond
  /// to the `source` and `target` properties of the `AVAssetTrackSegment` class.
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
/// {@template av_asset_track_meta}
/// A metadata object that represents a single track in an `AVAsset`.
///
/// This class is used to represent metadata for a single track in an `AVAsset`, which
/// includes its media type, time range, nominal frame rate, and segments. The `mediaType`
/// property indicates the type of media contained in the track (e.g., audio or video), while
/// the `timeRange` property represents the duration of the track. The `nominalFrameRate`
/// property indicates the expected frame rate of the track, and the `segments` property
/// is a list of `AVAssetTrackSegment` objects that define individual portions of the track.
/// {@endtemplate}
class AVAssetTrackMeta with IMappable {
  /// The media type of the asset track.
  final String mediaType;

  /// The time range of the asset track.
  final CMTimeRange timeRange;

  /// The nominal frame rate of the asset track.
  final double nominalFrameRate;

  /// The segments of the asset track.
  final List<AVAssetTrackSegment> segments;

  /// {@macro av_asset_track_meta}
  ///
  /// Creates a new `AVAssetTrackMeta` instance with the given properties.
  ///
  /// All parameters are required and must be non-null.
  AVAssetTrackMeta({
    required this.mediaType,
    required this.timeRange,
    required this.nominalFrameRate,
    required this.segments,
  });

  /// {@macro av_asset_track_meta}
  ///
  /// Creates a new `AVAssetTrackMeta` instance from a JSON map.
  ///
  /// The map should contain the keys `mediaType`, `timeRange`, `nominalFrameRate`,
  /// and `segments`, which correspond to the `mediaType`, `timeRange`, `nominalFrameRate`,
  /// and `segments` properties of the `AVAssetTrackMeta` class.
  factory AVAssetTrackMeta.fromJson(Map json) {
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
