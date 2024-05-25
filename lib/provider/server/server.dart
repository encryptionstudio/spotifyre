import 'dart:io';
import 'dart:math';

import 'package:catcher_2/catcher_2.dart';
import 'package:dio/dio.dart' hide Response;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:spotifyre/models/logger.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/provider/server/active_sourced_track.dart';
import 'package:spotifyre/provider/server/sourced_track.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_state.dart';

class PlaybackServer {
  final Ref ref;
  UserPreferences get userPreferences => ref.read(userPreferencesProvider);
  ProxyPlaylist get playlist => ref.read(proxyPlaylistProvider);
  final Logger logger;
  final Dio dio;

  final Router router;

  static final port = Random().nextInt(17000) + 1500;

  PlaybackServer(this.ref)
      : logger = getLogger('PlaybackServer'),
        dio = Dio(),
        router = Router() {
    router.get('/stream/<trackId>', getStreamTrackId);

    const pipeline = Pipeline();

    if (kDebugMode) {
      pipeline.addMiddleware(logRequests());
    }

    serve(pipeline.addHandler(router.call), InternetAddress.loopbackIPv4, port)
        .then((server) {
      logger
          .t('Playback server at http://${server.address.host}:${server.port}');

      ref.onDispose(() {
        dio.close(force: true);
        server.close();
      });
    });
  }

  /// @get('/stream/<trackId>')
  Future<Response> getStreamTrackId(Request request, String trackId) async {
    try {
      final track =
          playlist.tracks.firstWhere((element) => element.id == trackId);
      final activeSourcedTrack = ref.read(activeSourcedTrackProvider);
      final sourcedTrack = activeSourcedTrack?.id == track.id
          ? activeSourcedTrack
          : await ref.read(sourcedTrackProvider(track).future);

      ref.read(activeSourcedTrackProvider.notifier).update(sourcedTrack);

      final res = await dio.get(
        sourcedTrack!.url,
        options: Options(
          headers: {
            ...request.headers,
            "User-Agent":
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
            "host": Uri.parse(sourcedTrack.url).host,
            "Cache-Control": "max-age=0",
            "Connection": "keep-alive",
          },
          responseType: ResponseType.stream,
          validateStatus: (status) => status! < 500,
        ),
      );

      final audioStream =
          (res.data?.stream as Stream<Uint8List>?)?.asBroadcastStream();

      // if (res.statusCode! > 300) {
      // debugPrint(
      //   "[[Request]]\n"
      //   "URI: ${res.requestOptions.uri}\n"
      //   "Status: ${res.statusCode}\n"
      //   "Request Headers: ${res.requestOptions.headers}\n"
      //   "Response Body: ${res.data}\n"
      //   "Response Headers: ${res.headers.map}",
      // );
      // }

      audioStream!.listen(
        (event) {},
        cancelOnError: true,
      );

      return Response(
        res.statusCode!,
        body: audioStream,
        context: {
          "shelf.io.buffer_output": false,
        },
        headers: res.headers.map,
      );
    } catch (e, stack) {
      Catcher2.reportCheckedError(e, stack);
      return Response.internalServerError();
    }
  }
}

final playbackServerProvider = Provider<PlaybackServer>((ref) {
  return PlaybackServer(ref);
});
