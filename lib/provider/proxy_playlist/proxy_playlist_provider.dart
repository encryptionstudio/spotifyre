import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/extensions/track.dart';
import 'package:spotifyre/models/local_track.dart';

import 'package:spotifyre/provider/blacklist_provider.dart';
import 'package:spotifyre/provider/palette_provider.dart';
import 'package:spotifyre/provider/proxy_playlist/player_listeners.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist.dart';
import 'package:spotifyre/provider/scrobbler_provider.dart';
import 'package:spotifyre/provider/server/sourced_track.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_state.dart';
import 'package:spotifyre/services/audio_player/audio_player.dart';
import 'package:spotifyre/services/audio_services/audio_services.dart';
import 'package:spotifyre/provider/discord_provider.dart';

import 'package:spotifyre/utils/persisted_state_notifier.dart';

class ProxyPlaylistNotifier extends PersistedStateNotifier<ProxyPlaylist> {
  final Ref ref;
  late final AudioServices notificationService;

  ScrobblerNotifier get scrobbler => ref.read(scrobblerProvider.notifier);
  UserPreferences get preferences => ref.read(userPreferencesProvider);
  ProxyPlaylist get playlist => state;
  BlackListNotifier get blacklist => ref.read(blacklistProvider.notifier);
  Discord get discord => ref.read(discordProvider);

  List<StreamSubscription> _subscriptions = [];

  ProxyPlaylistNotifier(this.ref) : super(ProxyPlaylist({}), "playlist") {
    AudioServices.create(ref, this).then(
      (value) => notificationService = value,
    );

    _subscriptions = [
      // These are subscription methods from player_listeners.dart
      subscribeToPlaylist(),
      subscribeToSkipSponsor(),
      subscribeToPosition(),
      subscribeToScrobbleChanged(),
    ];
  }
  // Basic methods for adding or removing tracks to playlist

  Future<void> addTrack(Track track) async {
    if (blacklist.contains(track)) return;
    await audioPlayer.addTrack(spotifyreMedia(track));
  }

  Future<void> addTracks(Iterable<Track> tracks) async {
    tracks = blacklist.filter(tracks).toList() as List<Track>;
    for (final track in tracks) {
      await audioPlayer.addTrack(spotifyreMedia(track));
    }
  }

  void addCollection(String collectionId) {
    state = state.copyWith(collections: {
      ...state.collections,
      collectionId,
    });
  }

  void removeCollection(String collectionId) {
    state = state.copyWith(collections: {
      ...state.collections..remove(collectionId),
    });
  }

  Future<void> removeTrack(String trackId) async {
    final trackIndex =
        state.tracks.toList().indexWhere((element) => element.id == trackId);
    if (trackIndex == -1) return;
    await audioPlayer.removeTrack(trackIndex);
  }

  Future<void> removeTracks(Iterable<String> tracksIds) async {
    final tracks = state.tracks.map((t) => t.id!).toList();

    for (final track in tracks) {
      final index = tracks.indexOf(track);
      if (index == -1) continue;
      await audioPlayer.removeTrack(index);
    }
  }

  Future<void> load(
    Iterable<Track> tracks, {
    int initialIndex = 0,
    bool autoPlay = false,
  }) async {
    tracks = blacklist.filter(tracks).toList() as List<Track>;

    state = state.copyWith(collections: {});

    // Giving the initial track a boost so MediaKit won't skip
    // because of timeout
    final intendedActiveTrack = tracks.elementAt(initialIndex);
    if (intendedActiveTrack is! LocalTrack) {
      await ref.read(sourcedTrackProvider(intendedActiveTrack).future);
    }

    await audioPlayer.openPlaylist(
      tracks.asMediaList(),
      initialIndex: initialIndex,
      autoPlay: autoPlay,
    );
  }

  Future<void> jumpTo(int index) async {
    await audioPlayer.jumpTo(index);
  }

  Future<void> jumpToTrack(Track track) async {
    final index =
        state.tracks.toList().indexWhere((element) => element.id == track.id);
    if (index == -1) return;
    await jumpTo(index);
  }

  Future<void> moveTrack(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        newIndex < 0 ||
        oldIndex < 0 ||
        newIndex > state.tracks.length - 1 ||
        oldIndex > state.tracks.length - 1) return;

    await audioPlayer.moveTrack(oldIndex, newIndex);
  }

  Future<void> addTracksAtFirst(Iterable<Track> tracks) async {
    if (state.tracks.length == 1) {
      return addTracks(tracks);
    }

    tracks = blacklist.filter(tracks).toList() as List<Track>;

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks.elementAt(i);

      await audioPlayer.addTrackAt(
        spotifyreMedia(track),
        (state.active ?? 0) + i + 1,
      );
    }
  }

  Future<void> next() async {
    await audioPlayer.skipToNext();
  }

  Future<void> previous() async {
    await audioPlayer.skipToPrevious();
  }

  Future<void> stop() async {
    state = ProxyPlaylist({});
    await audioPlayer.stop();
    discord.clear();
  }

  Future<void> updatePalette() async {
    final palette = ref.read(paletteProvider);
    if (!preferences.albumColorSync) {
      if (palette != null) ref.read(paletteProvider.notifier).state = null;
      return;
    }
    return Future.microtask(() async {
      if (state.activeTrack == null) return;

      final palette = await PaletteGenerator.fromImageProvider(
        UniversalImage.imageProvider(
          (state.activeTrack?.album?.images).asUrlString(
            placeholder: ImagePlaceholder.albumArt,
          ),
          height: 50,
          width: 50,
        ),
      );
      ref.read(paletteProvider.notifier).state = palette;
    });
  }

  @override
  set state(state) {
    super.state = state;
    if (state.tracks.isEmpty && ref.read(paletteProvider) != null) {
      ref.read(paletteProvider.notifier).state = null;
    } else {
      updatePalette();
    }
  }

  @override
  onInit() async {
    if (state.tracks.isEmpty) return null;
    final oldCollections = state.collections;
    await load(
      state.tracks,
      initialIndex: max(state.active ?? 0, 0),
      autoPlay: false,
    );
    state = state.copyWith(collections: oldCollections);
  }

  @override
  FutureOr<ProxyPlaylist> fromJson(Map<String, dynamic> json) {
    return ProxyPlaylist.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = state.toJson();
    return json;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

final proxyPlaylistProvider =
    StateNotifierProvider<ProxyPlaylistNotifier, ProxyPlaylist>(
  (ref) => ProxyPlaylistNotifier(ref),
);
