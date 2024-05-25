import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/services/audio_player/audio_player.dart';
import 'package:spotifyre/services/sourced_track/models/source_info.dart';
import 'package:spotifyre/services/sourced_track/sourced_track.dart';

class ActiveSourcedTrackNotifier extends Notifier<SourcedTrack?> {
  @override
  build() {
    return null;
  }

  void update(SourcedTrack? sourcedTrack) {
    state = sourcedTrack;
  }

  Future<void> populateSibling() async {
    if (state == null) return;
    state = await state!.copyWithSibling();
  }

  Future<void> swapSibling(SourceInfo sibling) async {
    if (state == null) return;
    await populateSibling();
    final newTrack = await state!.swapWithSibling(sibling);
    if (newTrack == null) return;

    state = newTrack;
    await audioPlayer.pause();

    final playbackNotifier = ref.read(proxyPlaylistProvider.notifier);
    final oldActiveIndex = audioPlayer.currentIndex;

    await playbackNotifier.addTracksAtFirst([newTrack]);
    await Future.delayed(const Duration(milliseconds: 50));
    await playbackNotifier.jumpToTrack(newTrack);

    await audioPlayer.removeTrack(oldActiveIndex);

    await audioPlayer.resume();
  }
}

final activeSourcedTrackProvider =
    NotifierProvider<ActiveSourcedTrackNotifier, SourcedTrack?>(
  () => ActiveSourcedTrackNotifier(),
);
