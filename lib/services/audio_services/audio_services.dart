import 'package:audio_service/audio_service.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/extensions/artist_simple.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/services/audio_services/mobile_audio_service.dart';
import 'package:spotifyre/services/audio_services/windows_audio_service.dart';
import 'package:spotifyre/services/sourced_track/sourced_track.dart';

class AudioServices {
  final MobileAudioService? mobile;
  final WindowsAudioService? smtc;

  AudioServices(this.mobile, this.smtc);

  static Future<AudioServices> create(
    Ref ref,
    ProxyPlaylistNotifier playback,
  ) async {
    final mobile = DesktopTools.platform.isMobile ||
            DesktopTools.platform.isMacOS ||
            DesktopTools.platform.isLinux
        ? await AudioService.init(
            builder: () => MobileAudioService(playback),
            config: const AudioServiceConfig(
              androidNotificationChannelId: 'com.krtirtho.spotifyre',
              androidNotificationChannelName: 'spotifyre',
              androidNotificationOngoing: true,
            ),
          )
        : null;
    final smtc = DesktopTools.platform.isWindows
        ? WindowsAudioService(ref, playback)
        : null;

    return AudioServices(
      mobile,
      smtc,
    );
  }

  Future<void> addTrack(Track track) async {
    await smtc?.addTrack(track);
    mobile?.addItem(MediaItem(
      id: track.id!,
      album: track.album?.name ?? "",
      title: track.name!,
      artist: (track.artists)?.asString() ?? "",
      duration: track is SourcedTrack
          ? track.sourceInfo.duration
          : Duration(milliseconds: track.durationMs ?? 0),
      artUri: Uri.parse(
        (track.album?.images).asUrlString(
          placeholder: ImagePlaceholder.albumArt,
        ),
      ),
      playable: true,
    ));
  }

  void activateSession() {
    mobile?.session?.setActive(true);
  }

  void deactivateSession() {
    mobile?.session?.setActive(false);
  }

  void dispose() {
    smtc?.dispose();
  }
}
