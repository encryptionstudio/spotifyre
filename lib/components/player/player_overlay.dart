import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:spotifyre/components/player/player_track_details.dart';
import 'package:spotifyre/components/root/spotifyre_navigation_bar.dart';
import 'package:spotifyre/components/shared/panels/sliding_up_panel.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/collections/intents.dart';
import 'package:spotifyre/components/player/use_progress.dart';
import 'package:spotifyre/components/player/player.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/services/audio_player/audio_player.dart';

class PlayerOverlay extends HookConsumerWidget {
  final String albumArt;

  const PlayerOverlay({
    required this.albumArt,
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    final playlistNotifier = ref.watch(proxyPlaylistProvider.notifier);
    final playlist = ref.watch(proxyPlaylistProvider);
    final canShow = playlist.activeTrack != null;

    final playing =
        useStream(audioPlayer.playingStream).data ?? audioPlayer.isPlaying;

    final theme = Theme.of(context);
    final textColor = theme.colorScheme.primary;

    const radius = BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    );

    final mediaQuery = MediaQuery.of(context);

    final panelController = useMemoized(() => PanelController(), []);
    final scrollController = useScrollController();

    useEffect(() {
      return () {
        panelController.dispose();
      };
    }, []);

    return SlidingUpPanel(
      maxHeight: mediaQuery.size.height,
      backdropEnabled: false,
      minHeight: canShow ? 53 : 0,
      onPanelSlide: (position) {
        final invertedPosition = 1 - position;
        ref.read(navigationPanelHeight.notifier).state = 50 * invertedPosition;
      },
      controller: panelController,
      collapsed: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: mediaQuery.size.width,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(.8),
              borderRadius: radius,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: canShow ? 1 : 0,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HookBuilder(
                      builder: (context) {
                        final progress = useProgress(ref);
                        // animated
                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 250),
                          tween: Tween<double>(
                            begin: 0,
                            end: progress.progressStatic,
                          ),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 2,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                panelController.open();
                              },
                              child: Container(
                                width: double.infinity,
                                color: Colors.transparent,
                                child: PlayerTrackDetails(
                                  track: playlist.activeTrack,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  spotifyreIcons.skipBack,
                                  color: textColor,
                                ),
                                onPressed: playlist.isFetching
                                    ? null
                                    : playlistNotifier.previous,
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  return IconButton(
                                    icon: playlist.isFetching
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(),
                                          )
                                        : Icon(
                                            playing
                                                ? spotifyreIcons.pause
                                                : spotifyreIcons.play,
                                            color: textColor,
                                          ),
                                    onPressed: Actions.handler<PlayPauseIntent>(
                                      context,
                                      PlayPauseIntent(ref),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  spotifyreIcons.skipForward,
                                  color: textColor,
                                ),
                                onPressed: playlist.isFetching
                                    ? null
                                    : playlistNotifier.next,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      scrollController: scrollController,
      panelBuilder: (position) {
        // this is the reason we're getting an update
        final navigationHeight = ref.watch(navigationPanelHeight);

        if (navigationHeight == 50) return const SizedBox();

        return IgnorePointer(
          ignoring: !panelController.isPanelOpen,
          child: AnimatedContainer(
            clipBehavior: Clip.antiAlias,
            duration: const Duration(milliseconds: 250),
            decoration: navigationHeight == 0
                ? const BoxDecoration(borderRadius: BorderRadius.zero)
                : const BoxDecoration(borderRadius: radius),
            child: IgnoreDraggableWidget(
              child: PlayerView(
                panelController: panelController,
                scrollController: scrollController,
              ),
            ),
          ),
        );
      },
    );
  }
}
