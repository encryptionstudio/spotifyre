import 'package:catcher_2/catcher_2.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/provider/spotify_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotifyre/services/audio_player/audio_player.dart';

void useEndlessPlayback(WidgetRef ref) {
  final auth = ref.watch(authenticationProvider);
  final playback = ref.watch(proxyPlaylistProvider.notifier);
  final playlist = ref.watch(proxyPlaylistProvider);
  final spotify = ref.watch(spotifyProvider);
  final endlessPlayback =
      ref.watch(userPreferencesProvider.select((s) => s.endlessPlayback));

  useEffect(
    () {
      if (!endlessPlayback || auth == null) return null;

      void listener(int index) async {
        try {
          final playlist = ref.read(proxyPlaylistProvider);
          if (index != playlist.tracks.length - 1) return;

          final track = playlist.tracks.last;

          final query = "${track.name} Radio";
          final pages = await spotify.search
              .get(query, types: [SearchType.playlist]).first();

          final radios = pages
              .expand((e) => e.items?.toList() ?? <PlaylistSimple>[])
              .toList()
              .cast<PlaylistSimple>();

          final artists = track.artists!.map((e) => e.name);

          final radio = radios.firstWhere(
            (e) {
              final validPlaylists =
                  artists.where((a) => e.description!.contains(a!));
              return e.name == "${track.name} Radio" &&
                  (validPlaylists.length >= 2 ||
                      validPlaylists.length == artists.length) &&
                  e.owner?.displayName != "Spotify";
            },
            orElse: () => radios.first,
          );

          final tracks =
              await spotify.playlists.getTracksByPlaylistId(radio.id!).all();

          await playback.addTracks(
            tracks.toList()
              ..removeWhere((e) {
                final playlist = ref.read(proxyPlaylistProvider);
                final isDuplicate = playlist.tracks.any((t) => t.id == e.id);
                return e.id == track.id || isDuplicate;
              }),
          );
        } catch (e, stack) {
          Catcher2.reportCheckedError(e, stack);
        }
      }

      // Sometimes user can change settings for which the currentIndexChanged
      // might not be called. So we need to check if the current track is the
      // last track and if it is then we need to call the listener manually.
      if (playlist.active == playlist.tracks.length - 1 &&
          audioPlayer.isPlaying) {
        listener(playlist.active!);
      }

      final subscription =
          audioPlayer.currentIndexChangedStream.listen(listener);

      return subscription.cancel;
    },
    [
      spotify,
      playback,
      playlist.tracks,
      endlessPlayback,
      auth,
    ],
  );
}
