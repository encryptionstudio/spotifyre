import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/player/player_queue.dart';
import 'package:spotifyre/components/shared/dialogs/replace_downloaded_dialog.dart';
import 'package:spotifyre/components/root/bottom_player.dart';
import 'package:spotifyre/components/root/sidebar.dart';
import 'package:spotifyre/components/root/spotifyre_navigation_bar.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/hooks/configurators/use_endless_playback.dart';
import 'package:spotifyre/hooks/configurators/use_update_checker.dart';
import 'package:spotifyre/provider/connect/server.dart';
import 'package:spotifyre/provider/download_manager_provider.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/services/connectivity_adapter.dart';
import 'package:spotifyre/utils/persisted_state_notifier.dart';

const rootPaths = {
  "/": 0,
  "/search": 1,
  "/library": 2,
  "/lyrics": 3,
};

class RootApp extends HookConsumerWidget {
  final Widget child;
  const RootApp({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    final isMounted = useIsMounted();
    final showingDialogCompleter = useRef(Completer()..complete());
    final downloader = ref.watch(downloadManagerProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).matchedLocation;

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final sharedPreferences = await SharedPreferences.getInstance();

        if (sharedPreferences.getBool(kIsUsingEncryption) == false &&
            context.mounted) {
          await PersistedStateNotifier.showNoEncryptionDialog(context);
        }
      });

      final subscriptions = [
        ConnectionCheckerService.instance.onConnectivityChanged
            .listen((status) {
          if (status) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      spotifyreIcons.wifi,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 10),
                    Text(context.l10n.connection_restored),
                  ],
                ),
                backgroundColor: theme.colorScheme.primary,
                showCloseIcon: true,
                width: 350,
              ),
            );
          } else {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      spotifyreIcons.noWifi,
                      color: theme.colorScheme.onError,
                    ),
                    const SizedBox(width: 10),
                    Text(context.l10n.you_are_offline),
                  ],
                ),
                backgroundColor: theme.colorScheme.error,
                showCloseIcon: true,
                width: 300,
              ),
            );
          }
        }),
        connectClientStream.listen((clientOrigin) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: Colors.yellow[600],
              behavior: SnackBarBehavior.floating,
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    spotifyreIcons.error,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.connect_client_alert(clientOrigin),
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          );
        })
      ];

      return () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
      };
    }, []);

    useEffect(() {
      downloader.onFileExists = (track) async {
        if (!isMounted()) return false;

        if (!showingDialogCompleter.value.isCompleted) {
          await showingDialogCompleter.value.future;
        }

        final replaceAll = ref.read(replaceDownloadedFileState);

        if (replaceAll != null) return replaceAll;

        showingDialogCompleter.value = Completer();

        if (context.mounted) {
          final result = await showDialog<bool>(
                context: context,
                builder: (context) => ReplaceDownloadedDialog(
                  track: track,
                ),
              ) ??
              false;

          showingDialogCompleter.value.complete();
          return result;
        }

        // it'll never reach here as root_app is always mounted
        return false;
      };
      return null;
    }, [downloader]);

    // checks for latest version of the application
    useUpdateChecker(ref);

    useEndlessPlayback(ref);

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    useEffect(() {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: backgroundColor, // status bar color
          statusBarIconBrightness: backgroundColor.computeLuminance() > 0.179
              ? Brightness.dark
              : Brightness.light,
        ),
      );
      return null;
    }, [backgroundColor]);

    void onSelectIndexChanged(int d) {
      final invertedRouteMap =
          rootPaths.map((key, value) => MapEntry(value, key));

      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GoRouter.of(context).go(invertedRouteMap[d]!);
        });
      }
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (rootPaths[location] != 0) {
          onSelectIndexChanged(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Sidebar(
          selectedIndex: rootPaths[location],
          onSelectedIndexChanged: onSelectIndexChanged,
          child: child,
        ),
        extendBody: true,
        drawerScrimColor: Colors.transparent,
        endDrawer: DesktopTools.platform.isDesktop
            ? Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  boxShadow: theme.brightness == Brightness.light
                      ? null
                      : kElevationToShadow[8],
                ),
                margin: const EdgeInsets.only(
                  top: 40,
                  bottom: 100,
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final playlist = ref.watch(proxyPlaylistProvider);
                    final playlistNotifier =
                        ref.read(proxyPlaylistProvider.notifier);

                    return PlayerQueue.fromProxyPlaylistNotifier(
                      floating: true,
                      playlist: playlist,
                      notifier: playlistNotifier,
                    );
                  },
                ),
              )
            : null,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomPlayer(),
            spotifyreNavigationBar(
              selectedIndex: rootPaths[location],
              onSelectedIndexChanged: onSelectIndexChanged,
            ),
          ],
        ),
      ),
    );
  }
}
