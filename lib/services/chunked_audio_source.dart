import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

/// Streams audio from YouTube's CDN in small, bounded byte ranges.
///
/// googlevideo rejects open-ended range requests outright: `Range: bytes=0-`
/// and requests with no range at all both come back `403 Forbidden`, and so do
/// bounded ranges past roughly a quarter megabyte. Only small chunks are
/// served. Both players the app uses ask for open-ended ranges -- ExoPlayer via
/// DefaultHttpDataSource on Android, ffmpeg via mpv on desktop -- so playing a
/// CDN url directly fails on every platform.
///
/// [StreamAudioSource] sits in front of that: just_audio runs a local proxy and
/// asks this class for byte ranges, which we satisfy by issuing however many
/// chunk-sized requests the CDN will accept and stitching the responses back
/// into one continuous stream. Seeking still works, because just_audio asks the
/// proxy for the range it wants.
class ChunkedHttpAudioSource extends StreamAudioSource {
  ChunkedHttpAudioSource(this.uri, {super.tag});

  final Uri uri;

  /// Largest range the CDN reliably serves. 256 KiB responds with 206 while
  /// 1 MiB already returns 403, so stay a comfortable distance below that.
  static const int _chunkSize = 256 * 1024;

  int? _sourceLength;
  String? _contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final total = _sourceLength ??= await _resolveLength();
    final from = start ?? 0;
    // just_audio treats `end` as exclusive.
    final toExclusive = (end ?? total).clamp(from, total);

    return StreamAudioResponse(
      rangeRequestsSupported: true,
      sourceLength: total,
      contentLength: toExclusive - from,
      offset: from,
      contentType: _contentType ?? _mimeFromUri(),
      stream: _chunkedStream(from, toExclusive),
    );
  }

  /// Emits [from, toExclusive) as a sequence of chunk-sized ranged requests.
  Stream<List<int>> _chunkedStream(int from, int toExclusive) async* {
    final client = HttpClient();
    try {
      var position = from;
      while (position < toExclusive) {
        // Range headers are inclusive on both ends.
        final chunkLast =
            (position + _chunkSize).clamp(position, toExclusive) - 1;
        final request = await client.getUrl(uri);
        request.headers
            .set(HttpHeaders.rangeHeader, 'bytes=$position-$chunkLast');
        final response = await request.close();

        if (response.statusCode != HttpStatus.partialContent &&
            response.statusCode != HttpStatus.ok) {
          throw HttpException(
              'HTTP ${response.statusCode} for bytes=$position-$chunkLast',
              uri: uri);
        }

        var received = 0;
        await for (final data in response) {
          yield data;
          received += data.length;
        }
        if (received == 0) {
          // Nothing came back; without this the loop would spin forever.
          throw HttpException(
              'Empty response for bytes=$position-$chunkLast', uri: uri);
        }
        position += received;
      }
    } finally {
      client.close();
    }
  }

  /// CDN urls carry the exact payload size in `clen`, which saves a round trip.
  /// Fall back to a one-byte ranged request and read the total off Content-Range.
  Future<int> _resolveLength() async {
    final clen = int.tryParse(uri.queryParameters['clen'] ?? '');
    if (clen != null && clen > 0) {
      return clen;
    }

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      final response = await request.close();
      await response.drain<void>();
      _contentType ??= response.headers.contentType?.mimeType;

      final contentRange =
          response.headers.value(HttpHeaders.contentRangeHeader);
      final total = contentRange == null
          ? null
          : int.tryParse(contentRange.split('/').last);
      if (total == null || total <= 0) {
        throw HttpException('Could not determine audio length', uri: uri);
      }
      return total;
    } finally {
      client.close();
    }
  }

  /// The url states its own mime type, e.g. `mime=audio%2Fwebm` for opus.
  String _mimeFromUri() {
    final mime = uri.queryParameters['mime'];
    return (mime != null && mime.isNotEmpty) ? mime : 'audio/mp4';
  }
}
