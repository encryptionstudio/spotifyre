import 'dart:ui';

import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:spotifyre/collections/assets.gen.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/player/player_actions.dart';
import 'package:spotifyre/components/player/player_overlay.dart';
import 'package:spotifyre/components/player/player_track_details.dart';
import 'package:spotifyre/components/player/player_controls.dart';
import 'package:spotifyre/components/player/volume_slider.dart';
import 'package:spotifyre/extensions/constrains.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/hooks/utils/use_brightness_value.dart';
import 'package:spotifyre/models/logger.dart';
import 'package:flutter/material.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_state.dart';
import 'package:spotifyre/provider/volume_provider.dart';
import 'package:spotifyre/utils/platform.dart';

class BottomPlayer extends HookConsumerWidget {
  BottomPlayer({super.key});

  final logger = getLogger(BottomPlayer);
  @override
  Widget build(BuildContext context, ref) {
    final auth = ref.watch(authenticationProvider);
    final playlist = ref.watch(proxyPlaylistProvider);
    final layoutMode =
        ref.watch(userPreferencesProvider.select((s) => s.layoutMode));

    final mediaQuery = MediaQuery.of(context);

    String albumArt = useMemoized(
      () => playlist.activeTrack?.album?.images?.isNotEmpty == true
          ? (playlist.activeTrack?.album?.images).asUrlString(
              index: (playlist.activeTrack?.album?.images?.length ?? 1) - 1,
              placeholder: ImagePlaceholder.albumArt,
            )
          : Assets.albumPlaceholder.path,
      [playlist.activeTrack?.album?.images],
    );

    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceVariant;

    final bgColor = useBrightnessValue(
      Color.lerp(bg, Colors.white, 0.7),
      Color.lerp(bg, Colors.black, 0.45)!,
    );

    // returning an empty non spacious Container as the overlay will take
    // place in the global overlay stack aka [_entries]
    if (layoutMode == LayoutMode.compact ||
        ((mediaQuery.mdAndDown) && layoutMode == LayoutMode.adaptive)) {
      return PlayerOverlay(albumArt: albumArt);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: DecoratedBox(
          decoration: BoxDecoration(color: bgColor?.withOpacity(0.8)),
          child: Material(
            type: MaterialType.transparency,
            textStyle: theme.textTheme.bodyMedium!,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: PlayerTrackDetails(track: playlist.activeTrack),
                ),
                // controls
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: PlayerControls(),
                  ),
                ),
                // add to saved tracks
                Column(
                  children: [
                    PlayerActions(
                      extraActions: [
                        if (auth != null)
                          IconButton(
                            tooltip: context.l10n.mini_player,
                            icon: const Icon(spotifyreIcons.miniPlayer),
                            onPressed: () async {
                              final prevSize =
                                  await DesktopTools.window.getSize();
                              await DesktopTools.window.setMinimumSize(
                                const Size(300, 300),
                              );
                              await DesktopTools.window.setAlwaysOnTop(true);
                              if (!kIsLinux) {
                                await DesktopTools.window.setHasShadow(false);
                              }
                              await DesktopTools.window
                                  .setAlignment(Alignment.topRight);
                              await DesktopTools.window
                                  .setSize(const Size(400, 500));
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                                () async {
                                  GoRouter.of(context).go(
                                    '/mini-player',
                                    extra: prevSize,
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                    Container(
                      height: 40,
                      constraints: const BoxConstraints(maxWidth: 250),
                      padding: const EdgeInsets.only(right: 10),
                      child: Consumer(builder: (context, ref, _) {
                        final volume = ref.watch(volumeProvider);
                        return VolumeSlider(
                          fullWidth: true,
                          value: volume,
                          onChanged: (value) {
                            ref.read(volumeProvider.notifier).setVolume(value);
                          },
                        );
                      }),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
