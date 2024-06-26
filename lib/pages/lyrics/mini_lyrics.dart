import 'package:flutter/material.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/player/player_controls.dart';
import 'package:spotifyre/components/player/player_queue.dart';
import 'package:spotifyre/components/root/sidebar.dart';
import 'package:spotifyre/components/shared/fallbacks/anonymous_fallback.dart';
import 'package:spotifyre/components/shared/page_window_title_bar.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/hooks/utils/use_force_update.dart';
import 'package:spotifyre/pages/lyrics/plain_lyrics.dart';
import 'package:spotifyre/pages/lyrics/synced_lyrics.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/utils/platform.dart';

class MiniLyricsPage extends HookConsumerWidget {
  final Size prevSize;
  const MiniLyricsPage({super.key, required this.prevSize});

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);
    final update = useForceUpdate();
    final wasMaximized = useRef<bool>(false);

    final playlistQueue = ref.watch(proxyPlaylistProvider);

    final areaActive = useState(false);
    final hoverMode = useState(true);
    final showLyrics = useState(true);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        wasMaximized.value = await DesktopTools.window.isMaximized();
      });
      return null;
    }, []);

    final auth = ref.watch(authenticationProvider);

    if (auth == null) {
      return const Scaffold(
        appBar: PageWindowTitleBar(),
        body: AnonymousFallback(),
      );
    }

    return MouseRegion(
      onEnter: !hoverMode.value
          ? null
          : (event) {
              areaActive.value = true;
            },
      onExit: !hoverMode.value
          ? null
          : (event) {
              areaActive.value = false;
            },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.4),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: areaActive.value
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              secondChild: const SizedBox(),
              firstChild: DragToMoveArea(
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: Sidebar.brandLogo(),
                    ),
                    const Spacer(),
                    if (showLyrics.value)
                      SizedBox(
                        height: 30,
                        child: TabBar(
                          tabs: [
                            Tab(text: context.l10n.synced),
                            Tab(text: context.l10n.plain),
                          ],
                          isScrollable: true,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: context.l10n.lyrics,
                      icon: showLyrics.value
                          ? const Icon(spotifyreIcons.lyrics)
                          : const Icon(spotifyreIcons.lyricsOff),
                      style: ButtonStyle(
                        foregroundColor: showLyrics.value
                            ? MaterialStateProperty.all(
                                theme.colorScheme.primary)
                            : null,
                      ),
                      onPressed: () async {
                        showLyrics.value = !showLyrics.value;
                        areaActive.value = true;
                        hoverMode.value = false;

                        await DesktopTools.window.setSize(
                          showLyrics.value
                              ? const Size(400, 500)
                              : const Size(400, 150),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: context.l10n.show_hide_ui_on_hover,
                      icon: hoverMode.value
                          ? const Icon(spotifyreIcons.hoverOn)
                          : const Icon(spotifyreIcons.hoverOff),
                      style: ButtonStyle(
                        foregroundColor: hoverMode.value
                            ? MaterialStateProperty.all(
                                theme.colorScheme.primary)
                            : null,
                      ),
                      onPressed: () async {
                        areaActive.value = true;
                        hoverMode.value = !hoverMode.value;
                      },
                    ),
                    FutureBuilder(
                      future: DesktopTools.window.isAlwaysOnTop(),
                      builder: (context, snapshot) {
                        return IconButton(
                          tooltip: context.l10n.always_on_top,
                          icon: Icon(
                            snapshot.data == true
                                ? spotifyreIcons.pinOn
                                : spotifyreIcons.pinOff,
                          ),
                          style: ButtonStyle(
                            foregroundColor: snapshot.data == true
                                ? MaterialStateProperty.all(
                                    theme.colorScheme.primary)
                                : null,
                          ),
                          onPressed: snapshot.data == null
                              ? null
                              : () async {
                                  await DesktopTools.window.setAlwaysOnTop(
                                    snapshot.data == true ? false : true,
                                  );
                                  update();
                                },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              if (playlistQueue.activeTrack != null)
                Text(
                  playlistQueue.activeTrack!.name!,
                  style: theme.textTheme.titleMedium,
                ),
              if (showLyrics.value)
                Expanded(
                  child: TabBarView(
                    children: [
                      SyncedLyrics(
                        palette: PaletteColor(theme.colorScheme.background, 0),
                        isModal: true,
                        defaultTextZoom: 65,
                      ),
                      PlainLyrics(
                        palette: PaletteColor(theme.colorScheme.background, 0),
                        isModal: true,
                        defaultTextZoom: 65,
                      ),
                    ],
                  ),
                )
              else
                const Gap(20),
              AnimatedCrossFade(
                crossFadeState: areaActive.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
                secondChild: const SizedBox(),
                firstChild: Row(
                  children: [
                    IconButton(
                      icon: const Icon(spotifyreIcons.queue),
                      tooltip: context.l10n.queue,
                      onPressed: playlistQueue.activeTrack != null
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                isDismissible: true,
                                enableDrag: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.black12,
                                barrierColor: Colors.black12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * .7,
                                ),
                                builder: (context) {
                                  return Consumer(builder: (context, ref, _) {
                                    final playlist =
                                        ref.watch(proxyPlaylistProvider);

                                    return PlayerQueue
                                        .fromProxyPlaylistNotifier(
                                      floating: true,
                                      playlist: playlist,
                                      notifier: ref
                                          .read(proxyPlaylistProvider.notifier),
                                    );
                                  });
                                },
                              );
                            }
                          : null,
                    ),
                    Flexible(child: PlayerControls(compact: true)),
                    IconButton(
                      tooltip: context.l10n.exit_mini_player,
                      icon: const Icon(spotifyreIcons.maximize),
                      onPressed: () async {
                        try {
                          await DesktopTools.window
                              .setMinimumSize(const Size(300, 700));
                          await DesktopTools.window.setAlwaysOnTop(false);
                          if (wasMaximized.value) {
                            await DesktopTools.window.maximize();
                          } else {
                            await DesktopTools.window.setSize(prevSize);
                          }
                          await DesktopTools.window
                              .setAlignment(Alignment.center);
                          if (!kIsLinux) {
                            await DesktopTools.window.setHasShadow(true);
                          }
                          await Future.delayed(
                              const Duration(milliseconds: 200));
                        } finally {
                          if (context.mounted) {
                            GoRouter.of(context).go('/lyrics');
                          }
                        }
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
