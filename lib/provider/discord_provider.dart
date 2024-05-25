import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/collections/env.dart';
import 'package:spotifyre/extensions/artist_simple.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';

class Discord extends ChangeNotifier {
  final DiscordRPC? discordRPC;
  final bool isEnabled;

  Discord(this.isEnabled)
      : discordRPC = (DesktopTools.platform.isWindows ||
                    DesktopTools.platform.isLinux) &&
                isEnabled
            ? DiscordRPC(applicationId: Env.discordAppId)
            : null {
    discordRPC?.start(autoRegister: true);
  }

  void updatePresence(Track track) {
    clear();
    final artistNames = track.artists?.asString() ?? "";
    discordRPC?.updatePresence(
      DiscordPresence(
        details: "Song: ${track.name} by $artistNames",
        state: "Vibing in Music",
        startTimeStamp: DateTime.now().millisecondsSinceEpoch,
        largeImageKey: "spotifyre-logo-foreground",
        largeImageText: "spotifyre",
        smallImageKey: "spotifyre-logo-foreground",
        smallImageText: "spotifyre",
      ),
    );
  }

  void clear() {
    discordRPC?.clearPresence();
  }

  void shutdown() {
    discordRPC?.shutDown();
  }

  @override
  void dispose() {
    clear();
    shutdown();
    super.dispose();
  }
}

final discordProvider = ChangeNotifierProvider(
  (ref) {
    final isEnabled =
        ref.watch(userPreferencesProvider.select((s) => s.discordPresence));
    final playback = ref.read(proxyPlaylistProvider);
    final discord = Discord(isEnabled);

    if (playback.activeTrack != null) {
      discord.updatePresence(playback.activeTrack!);
    }

    return discord;
  },
);
