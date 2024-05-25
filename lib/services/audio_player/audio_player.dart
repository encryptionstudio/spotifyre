import 'dart:io';

import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/foundation.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/extensions/track.dart';
import 'package:spotifyre/models/local_track.dart';
import 'package:spotifyre/provider/server/server.dart';
import 'package:spotifyre/services/audio_player/custom_player.dart';
import 'dart:async';

import 'package:media_kit/media_kit.dart' as mk;

import 'package:spotifyre/services/audio_player/loop_mode.dart';
import 'package:spotifyre/services/audio_player/playback_state.dart';

part 'audio_players_streams_mixin.dart';
part 'audio_player_impl.dart';

class spotifyreMedia extends mk.Media {
  final Track track;

  spotifyreMedia(
    this.track, {
    Map<String, String>? extras,
    super.httpHeaders,
  }) : super(
          track is LocalTrack
              ? track.path
              : "http://${InternetAddress.loopbackIPv4.address}:${PlaybackServer.port}/stream/${track.id}",
          extras: {
            ...?extras,
            "track": track.toJson(),
          },
        );

  factory spotifyreMedia.fromMedia(mk.Media media) {
    final track = Track.fromJson(media.extras?["track"]);
    return spotifyreMedia(track);
  }
}

abstract class AudioPlayerInterface {
  final CustomPlayer _mkPlayer;

  AudioPlayerInterface()
      : _mkPlayer = CustomPlayer(
          configuration: const mk.PlayerConfiguration(
            title: "spotifyre",
            logLevel: kDebugMode ? mk.MPVLogLevel.info : mk.MPVLogLevel.error,
          ),
        ) {
    _mkPlayer.stream.error.listen((event) {
      Catcher2.reportCheckedError(event, StackTrace.current);
    });
  }

  /// Whether the current platform supports the audioplayers plugin
  static const bool _mkSupportedPlatform = true;

  bool get mkSupportedPlatform => _mkSupportedPlatform;

  Future<Duration?> get duration async {
    return _mkPlayer.state.duration;
  }

  Future<Duration?> get position async {
    return _mkPlayer.state.position;
  }

  Future<Duration?> get bufferedPosition async {
    return _mkPlayer.state.buffer;
  }

  Future<mk.AudioDevice> get selectedDevice async {
    return _mkPlayer.state.audioDevice;
  }

  Future<List<mk.AudioDevice>> get devices async {
    return _mkPlayer.state.audioDevices;
  }

  bool get hasSource {
    return _mkPlayer.state.playlist.medias.isNotEmpty;
  }

  // states
  bool get isPlaying {
    return _mkPlayer.state.playing;
  }

  bool get isPaused {
    return !_mkPlayer.state.playing;
  }

  bool get isStopped {
    return !hasSource;
  }

  Future<bool> get isCompleted async {
    return _mkPlayer.state.completed;
  }

  Future<bool> get isShuffled async {
    return _mkPlayer.shuffled;
  }

  PlaybackLoopMode get loopMode {
    return PlaybackLoopMode.fromPlaylistMode(_mkPlayer.state.playlistMode);
  }

  /// Returns the current volume of the player, between 0 and 1
  double get volume {
    return _mkPlayer.state.volume / 100;
  }

  bool get isBuffering {
    return _mkPlayer.state.buffering;
  }
}
