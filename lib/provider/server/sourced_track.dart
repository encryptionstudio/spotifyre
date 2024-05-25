import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/models/local_track.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/services/sourced_track/sourced_track.dart';

final sourcedTrackProvider =
    FutureProvider.family<SourcedTrack?, Track?>((ref, track) async {
  if (track == null || track is LocalTrack) {
    return null;
  }

  ref.listen(
    proxyPlaylistProvider,
    (old, next) {
      if (next.tracks.isEmpty ||
          next.tracks.none((element) => element.id == track.id)) {
        ref.invalidateSelf();
      }
    },
  );

  final sourcedTrack =
      await SourcedTrack.fetchFromTrack(track: track, ref: ref);

  return sourcedTrack;
});
