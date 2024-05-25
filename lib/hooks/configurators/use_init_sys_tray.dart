import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotifyre/collections/intents.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';

void useInitSysTray(WidgetRef ref) {
  final context = useContext();
  final systemTray = useRef<SystemTray?>(null);

  final initializeMenu = useCallback(() async {
    systemTray.value?.destroy();
    final playlist = ref.read(proxyPlaylistProvider);
    final playlistQueue = ref.read(proxyPlaylistProvider.notifier);
    final preferences = ref.read(userPreferencesProvider);
    if (!preferences.showSystemTrayIcon) {
      await systemTray.value?.destroy();
      systemTray.value = null;
      return;
    }
    final enabled = !playlist.isFetching;
    systemTray.value = await DesktopTools.createSystemTrayMenu(
      title: DesktopTools.platform.isWindows ? "spotifyre" : "",
      iconPath: "assets/spotifyre-logo.png",
      windowsIconPath: "assets/spotifyre-logo.ico",
      items: [
        MenuItemLabel(
          label: "Show/Hide",
          name: "show-hide",
          onClicked: (item) async {
            if (await DesktopTools.window.isVisible()) {
              await DesktopTools.window.hide();
            } else {
              await DesktopTools.window.show();
            }
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: "Play/Pause",
          name: "play-pause",
          enabled: enabled,
          onClicked: (_) async {
            Actions.maybeInvoke<PlayPauseIntent>(
                    context, PlayPauseIntent(ref)) ??
                PlayPauseAction().invoke(PlayPauseIntent(ref));
          },
        ),
        MenuItemLabel(
          label: "Next",
          name: "next",
          enabled: enabled && (playlist.tracks.length) > 1,
          onClicked: (p0) async {
            await playlistQueue.next();
          },
        ),
        MenuItemLabel(
          label: "Previous",
          name: "previous",
          enabled: enabled && (playlist.tracks.length) > 1,
          onClicked: (p0) async {
            await playlistQueue.previous();
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: "Quit",
          name: "quit",
          onClicked: (item) async {
            exit(0);
          },
        ),
      ],
      onEvent: (event, tray) async {
        if (DesktopTools.platform.isWindows) {
          switch (event) {
            case SystemTrayEvent.click:
              await DesktopTools.window.show();
              break;
            case SystemTrayEvent.rightClick:
              await tray.popUpContextMenu();
              break;
            default:
          }
        } else {
          switch (event) {
            case SystemTrayEvent.rightClick:
              await DesktopTools.window.show();
              break;
            case SystemTrayEvent.click:
              await tray.popUpContextMenu();
              break;
            default:
          }
        }
      },
    );
  }, [ref]);

  useReassemble(initializeMenu);

  ref.listen<ProxyPlaylist?>(
    proxyPlaylistProvider,
    (previous, next) {
      initializeMenu();
    },
  );
  ref.listen(
    userPreferencesProvider.select((s) => s.showSystemTrayIcon),
    (previous, next) {
      initializeMenu();
    },
  );

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeMenu();
    });
    return () async {
      await systemTray.value?.destroy();
    };
  }, [initializeMenu]);
}
