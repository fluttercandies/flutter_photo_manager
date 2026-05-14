// A Dart port of MotionPhotoMuxer (https://github.com/mihir-io/MotionPhotoMuxer).
//
// Merges a JPEG photo and a MOV/MP4 video into a single Google Motion Photo
// (MicroVideo-formatted JPEG with embedded video and XMP metadata).
//
// Usage:
//   dart run scripts/motion_photo_muxer.dart --photo photo.jpg --video video.mov
//   dart run scripts/motion_photo_muxer.dart --dir /path/to/photos --recurse
//   dart run scripts/motion_photo_muxer.dart --help
//
// Original Python: https://github.com/mihir-io/MotionPhotoMuxer
// License: GPLv3

import 'dart:io';
import 'dart:typed_data';

// ---------------------------------------------------------------------------
// Media pair helper
// ---------------------------------------------------------------------------

/// A simple pair of photo and video files.
class MediaPair {
  MediaPair(this.photo, this.video);

  final File photo;
  final File video;
}

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------

bool _verbose = false;

void _logInfo(String message) {
  if (_verbose) {
    stdout.writeln('[INFO] $message');
  }
}

void _logError(String message) {
  stderr.writeln('[ERROR] $message');
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

/// Validates that [dir] exists and is a directory.
void validateDirectory(Directory dir) {
  if (!dir.existsSync()) {
    _logError("Path doesn't exist: ${dir.path}");
    exit(1);
  }
  if (!FileSystemEntity.isDirectorySync(dir.path)) {
    _logError('Path is not a directory: ${dir.path}');
    exit(1);
  }
}

/// Checks if [photoPath] is a JPEG and [videoPath] is a MOV/MP4.
bool validateMedia(File photoPath, File videoPath) {
  if (!photoPath.existsSync()) {
    _logError('Photo does not exist: ${photoPath.path}');
    return false;
  }
  if (!videoPath.existsSync()) {
    _logError('Video does not exist: ${videoPath.path}');
    return false;
  }
  final photoExt = _extension(photoPath.path);
  if (photoExt != '.jpg' && photoExt != '.jpeg') {
    _logError("Photo isn't a JPEG: ${photoPath.path}");
    return false;
  }
  final videoExt = _extension(videoPath.path);
  if (videoExt != '.mov' && videoExt != '.mp4') {
    _logError("Video isn't a MOV or MP4: ${videoPath.path}");
    return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Merge
// ---------------------------------------------------------------------------

/// Concatenates [photoPath] and [videoPath] into a single file under
/// [outputDir], using the photo's filename.  Returns the merged [File].
File mergeFiles(File photoPath, File videoPath, Directory outputDir) {
  _logInfo('Merging ${photoPath.path} and ${videoPath.path}.');
  final outPath = File('${outputDir.path}/${_basename(photoPath.path)}');
  outPath.parent.createSync(recursive: true);
  final sink = outPath.openSync(mode: FileMode.write);
  try {
    sink.writeFromSync(photoPath.readAsBytesSync());
    sink.writeFromSync(videoPath.readAsBytesSync());
  } finally {
    sink.closeSync();
  }
  _logInfo('Merged photo and video.');
  return outPath;
}

// ---------------------------------------------------------------------------
// XMP metadata injection
// ---------------------------------------------------------------------------

/// Generates the XMP/RDF payload that marks the file as a Motion Photo.
///
/// [videoOffset] is the number of bytes from EOF to the start of the
/// embedded video (i.e. `mergedSize - photoSize`).
String _buildXmpPayload(int videoOffset) {
  return '''<?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description
        xmlns:GCamera="http://ns.google.com/photos/1.0/camera/"
        xmlns:Camera="http://ns.google.com/photos/1.0/camera/"
        xmlns:Container="http://ns.google.com/photos/1.0/container/"
        xmlns:Item="http://ns.google.com/photos/1.0/container/item/"
        Camera:MotionPhoto="1"
        Camera:MotionPhotoVersion="1"
        Camera:MotionPhotoPresentationTimestampUs="1500000"
        GCamera:MicroVideo="1"
        GCamera:MicroVideoVersion="1"
        GCamera:MicroVideoOffset="$videoOffset"
        GCamera:MicroVideoPresentationTimestampUs="1500000">
      <Container:Directory>
        <rdf:Seq>
          <rdf:li rdf:parseType="Resource">
            <Container:Item
                Item:Mime="image/jpeg"
                Item:Semantic="Primary"/>
          </rdf:li>
          <rdf:li rdf:parseType="Resource">
            <Container:Item
                Item:Mime="video/mp4"
                Item:Semantic="MotionPhoto"
                Item:Length="$videoOffset"/>
          </rdf:li>
        </rdf:Seq>
      </Container:Directory>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>''';
}

/// The XMP APP1 namespace identifier followed by a null byte.
final Uint8List _xmpApp1Header =
    Uint8List.fromList('http://ns.adobe.com/xap/1.0/\x00'.codeUnits);

/// Injects Motion-Photo XMP into [mergedFile] **in-place**.
///
/// Because Dart has no py3exiv2, we do it at the JPEG byte level:
///  1. Read the merged JPEG.
///  2. Strip any pre-existing XMP APP1 segment (keep EXIF APP1 intact).
///  3. Insert a new XMP APP1 segment right after the SOI marker.
///  4. Overwrite the file.
void addXmpMetadata(File mergedFile, int offset) {
  _logInfo('Adding XMP metadata with offset=$offset to ${mergedFile.path}.');

  final Uint8List original = mergedFile.readAsBytesSync();

  if (original.length < 2 || original[0] != 0xFF || original[1] != 0xD8) {
    _logError('${mergedFile.path} is not a valid JPEG (missing SOI).');
    return;
  }

  // Build the XMP payload bytes.
  final xmpXml = _buildXmpPayload(offset);
  final xmpBody = Uint8List.fromList([
    ..._xmpApp1Header,
    ...xmpXml.codeUnits,
  ]);
  final segmentLength = 2 + xmpBody.length; // 2 bytes for the length field
  if (segmentLength > 0xFFFF) {
    _logError('XMP payload too large for a single APP1 segment.');
    return;
  }

  // Strip existing XMP APP1 from the file (preserve EXIF APP1).
  final stripped = _stripXmpApp1(original);

  // Reassemble: SOI + new XMP APP1 + rest of file
  final out = BytesBuilder(copy: false);
  // SOI
  out.addByte(0xFF);
  out.addByte(0xD8);
  // APP1 marker
  out.addByte(0xFF);
  out.addByte(0xE1);
  // Segment length (big-endian)
  out.addByte((segmentLength >> 8) & 0xFF);
  out.addByte(segmentLength & 0xFF);
  // XMP body
  out.add(xmpBody);
  // Remainder of JPEG (skip SOI we already wrote)
  out.add(Uint8List.sublistView(stripped, 2));

  mergedFile.writeAsBytesSync(out.toBytes());
  _logInfo('XMP metadata written.');
}

/// Returns [data] with any XMP-type APP1 segments removed.
/// EXIF APP1 (identifier "Exif\x00\x00") is kept.
Uint8List _stripXmpApp1(Uint8List data) {
  final xmpPrefix = _xmpApp1Header;
  final out = BytesBuilder(copy: false);
  // Write SOI
  out.addByte(data[0]);
  out.addByte(data[1]);
  int i = 2;

  while (i < data.length - 1) {
    if (data[i] == 0xFF && data[i + 1] == 0xE1) {
      // APP1 segment
      if (i + 3 < data.length) {
        final segLen = (data[i + 2] << 8) | data[i + 3];
        final segEnd = i + 2 + segLen;
        // Check if it's XMP
        final prefixEnd = i + 4 + xmpPrefix.length;
        if (prefixEnd <= data.length && segEnd <= data.length) {
          bool isXmp = true;
          for (int j = 0; j < xmpPrefix.length; j++) {
            if (data[i + 4 + j] != xmpPrefix[j]) {
              isXmp = false;
              break;
            }
          }
          if (isXmp) {
            // Skip this XMP APP1 segment entirely
            i = segEnd;
            continue;
          }
        }
        // Not XMP → keep it
        out.add(Uint8List.sublistView(data, i, segEnd.clamp(i, data.length)));
        i = segEnd;
      } else {
        out.add(Uint8List.sublistView(data, i));
        break;
      }
    } else if (data[i] == 0xFF && (data[i + 1] & 0xF0) == 0xE0) {
      // Other APPn markers → copy as-is
      if (i + 3 < data.length) {
        final segLen = (data[i + 2] << 8) | data[i + 3];
        final segEnd = i + 2 + segLen;
        if (segEnd <= data.length) {
          out.add(Uint8List.sublistView(data, i, segEnd));
          i = segEnd;
        } else {
          out.add(Uint8List.sublistView(data, i));
          break;
        }
      } else {
        out.add(Uint8List.sublistView(data, i));
        break;
      }
    } else {
      // SOS / non-APP marker → copy the rest verbatim
      out.add(Uint8List.sublistView(data, i));
      break;
    }
  }
  return out.toBytes();
}

// ---------------------------------------------------------------------------
// Conversion pipeline
// ---------------------------------------------------------------------------

/// Merges [photoPath] and [videoPath] into [outputDir], then injects XMP.
void convert(File photoPath, File videoPath, Directory outputDir) {
  final merged = mergeFiles(photoPath, videoPath, outputDir);
  final photoFilesize = photoPath.lengthSync();
  final mergedFilesize = merged.lengthSync();

  // offset = number of bytes from EOF to where the video begins
  final offset = mergedFilesize - photoFilesize;
  addXmpMetadata(merged, offset);
}

// ---------------------------------------------------------------------------
// Directory scanning
// ---------------------------------------------------------------------------

/// Returns the matching video file for [photoPath], or `null`.
File? matchingVideo(File photoPath) {
  final base = _withoutExtension(photoPath.path);
  _logInfo('Looking for videos named: $base');
  for (final ext in ['.mov', '.mp4', '.MOV', '.MP4']) {
    final candidate = File('$base$ext');
    if (candidate.existsSync()) {
      return candidate;
    }
  }
  return null;
}

/// Scans [fileDir] for JPEG+video pairs. If [recurse], walks subdirectories.
List<MediaPair> processDirectory(
  Directory fileDir,
  bool recurse,
) {
  _logInfo('Processing dir: ${fileDir.path}');
  final List<MediaPair> pairs = <MediaPair>[];
  final entities = recurse
      ? fileDir.listSync(recursive: true)
      : fileDir.listSync();
  for (final entity in entities) {
    if (entity is File) {
      final ext = _extension(entity.path);
      if (ext == '.jpg' || ext == '.jpeg') {
        final video = matchingVideo(entity);
        if (video != null) {
          pairs.add(MediaPair(entity, video));
        }
      }
    }
  }
  _logInfo('Found ${pairs.length} pairs.');
  if (pairs.isNotEmpty) {
    final preview =
        pairs.take(9).map((p) => '(${p.photo.path}, ${p.video.path})');
    _logInfo('Subset of found image/video pairs: $preview');
  }
  return pairs;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _extension(String path) {
  final dot = path.lastIndexOf('.');
  return dot == -1 ? '' : path.substring(dot).toLowerCase();
}

String _basename(String path) {
  final sep = path.lastIndexOf(Platform.pathSeparator);
  return sep == -1 ? path : path.substring(sep + 1);
}

String _withoutExtension(String path) {
  final dot = path.lastIndexOf('.');
  return dot == -1 ? path : path.substring(0, dot);
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

void _printUsage() {
  stdout.writeln('''
usage: motion_photo_muxer.dart [options]

Merges a photo and video into a Microvideo-formatted Google Motion Photo.

options:
  --help, -h        Show this help message and exit.
  --verbose         Show logging messages.
  --dir DIR         Process a directory for photos/videos.
                    Takes precedence over --photo/--video.
  --recurse         Recursively process a directory.
                    Only applies if --dir is also provided.
  --photo PHOTO     Path to the JPEG photo to add.
  --video VIDEO     Path to the MOV/MP4 video to add.
  --output OUTPUT   Path to where files should be written out to.
                    Defaults to "output".
  --copyall         Copy unpaired files to output directory.
''');
}

void main(List<String> arguments) {
  // ---- parse arguments ----------------------------------------------------
  String? dirArg;
  String? photoArg;
  String? videoArg;
  String? outputArg;
  bool recurse = false;
  bool copyAll = false;

  for (int i = 0; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      case '--verbose':
        _verbose = true;
        break;
      case '--recurse':
        recurse = true;
        break;
      case '--copyall':
        copyAll = true;
        break;
      case '--dir':
        i++;
        if (i >= arguments.length) {
          _logError('--dir requires a value');
          exit(1);
        }
        dirArg = arguments[i];
        break;
      case '--photo':
        i++;
        if (i >= arguments.length) {
          _logError('--photo requires a value');
          exit(1);
        }
        photoArg = arguments[i];
        break;
      case '--video':
        i++;
        if (i >= arguments.length) {
          _logError('--video requires a value');
          exit(1);
        }
        videoArg = arguments[i];
        break;
      case '--output':
        i++;
        if (i >= arguments.length) {
          _logError('--output requires a value');
          exit(1);
        }
        outputArg = arguments[i];
        break;
      default:
        _logError('Unknown argument: ${arguments[i]}');
        _printUsage();
        exit(1);
    }
  }

  _logInfo('Enabled verbose logging');

  final outDir = Directory(outputArg ?? 'output');

  // ---- directory mode -----------------------------------------------------
  if (dirArg != null) {
    final dir = Directory(dirArg);
    validateDirectory(dir);
    final pairs = processDirectory(dir, recurse);

    final processedFiles = <String>{};
    for (final pair in pairs) {
      if (validateMedia(pair.photo, pair.video)) {
        convert(pair.photo, pair.video, outDir);
        processedFiles.add(pair.photo.path);
        processedFiles.add(pair.video.path);
      }
    }

    if (copyAll) {
      final allFiles = dir
          .listSync()
          .whereType<File>()
          .toSet();
      final remaining =
          allFiles.where((f) => !processedFiles.contains(f.path)).toList();

      _logInfo('Found ${remaining.length} remaining files that will be copied.');

      if (remaining.isNotEmpty) {
        outDir.createSync(recursive: true);
        for (final file in remaining) {
          final dest = File('${outDir.path}/${_basename(file.path)}');
          file.copySync(dest.path);
        }
      }
    }
    return;
  }

  // ---- single-file mode ---------------------------------------------------
  if (photoArg == null && videoArg == null) {
    _logError('Either --dir or --photo and --video are required.');
    _printUsage();
    exit(1);
  }

  if ((photoArg == null) != (videoArg == null)) {
    _logError('Both --photo and --video must be provided.');
    exit(1);
  }

  final photo = File(photoArg!);
  final video = File(videoArg!);
  if (validateMedia(photo, video)) {
    convert(photo, video, outDir);
  }
}
