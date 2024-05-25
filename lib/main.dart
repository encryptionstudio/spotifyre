import 'package:catcher_2/catcher_2.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotifyre/collections/initializers.dart';
import 'package:spotifyre/collections/routes.dart';
import 'package:spotifyre/collections/intents.dart';
import 'package:spotifyre/hooks/configurators/use_close_behavior.dart';
import 'package:spotifyre/hooks/configurators/use_deep_linking.dart';
import 'package:spotifyre/hooks/configurators/use_disable_battery_optimizations.dart';
import 'package:spotifyre/hooks/configurators/use_get_storage_perms.dart';
import 'package:spotifyre/l10n/l10n.dart';
import 'package:spotifyre/models/logger.dart';
import 'package:spotifyre/models/skip_segment.dart';
import 'package:spotifyre/models/source_match.dart';
import 'package:spotifyre/provider/connect/clients.dart';
import 'package:spotifyre/provider/connect/server.dart';
import 'package:spotifyre/provider/palette_provider.dart';
import 'package:spotifyre/provider/server/server.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotifyre/services/audio_player/audio_player.dart';
import 'package:spotifyre/services/cli/cli.dart';
import 'package:spotifyre/services/kv_store/kv_store.dart';
import 'package:spotifyre/themes/theme.dart';
import 'package:spotifyre/utils/persisted_state_notifier.dart';
import 'package:system_theme/system_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotifyre/hooks/configurators/use_init_sys_tray.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main(List<String> rawArgs) async {
  final arguments = await startCLI(rawArgs);

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await registerWindowsScheme("spotify");

  tz.initializeTimeZones();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  MediaKit.ensureInitialized();

  // force High Refresh Rate on some Android devices (like One Plus)
  if (DesktopTools.platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }

  if (DesktopTools.platform.isDesktop) {
    await DesktopTools.window.setPreventClose(true);
  }

  await SystemTheme.accentColor.load();

  if (!kIsWeb) {
    MetadataGod.initialize();
  }

  if (DesktopTools.platform.isWindows || DesktopTools.platform.isLinux) {
    DiscordRPC.initialize();
  }

  await KVStoreService.initialize();

  final hiveCacheDir =
      kIsWeb ? null : (await getApplicationSupportDirectory()).path;

  Hive.init(hiveCacheDir);

  Hive.registerAdapter(SkipSegmentAdapter());

  Hive.registerAdapter(SourceMatchAdapter());
  Hive.registerAdapter(SourceTypeAdapter());

  // Cache versioning entities with Adapter
  SourceMatch.version = 'v1';
  SkipSegment.version = 'v1';

  await Hive.openLazyBox<SourceMatch>(
    SourceMatch.boxName,
    path: hiveCacheDir,
  );
  await Hive.openLazyBox(
    SkipSegment.boxName,
    path: hiveCacheDir,
  );
  await PersistedStateNotifier.initializeBoxes(
    path: hiveCacheDir,
  );

  await DesktopTools.ensureInitialized(
    DesktopWindowOptions(
      hideTitleBar: true,
      title: "spotifyre",
      backgroundColor: Colors.transparent,
      minimumSize: const Size(300, 700),
    ),
  );

  Catcher2(
    enableLogger: arguments["verbose"],
    debugConfig: Catcher2Options(
      SilentReportMode(),
      [
        ConsoleHandler(
          enableDeviceParameters: false,
          enableApplicationParameters: false,
        ),
        if (!kIsWeb) FileHandler(await getLogsPath(), printLogs: false),
      ],
    ),
    releaseConfig: Catcher2Options(
      SilentReportMode(),
      [
        if (arguments["verbose"] ?? false) ConsoleHandler(),
        if (!kIsWeb)
          FileHandler(
            await getLogsPath(),
            printLogs: false,
          ),
      ],
    ),
    runAppFunction: () {
      runApp(
        ProviderScope(
          child: DevicePreview(
            availableLocales: L10n.all,
            enabled: false,
            data: const DevicePreviewData(
              isEnabled: false,
              orientation: Orientation.portrait,
            ),
            builder: (context) {
              return const spotifyre();
            },
          ),
        ),
      );
    },
  );
}

class spotifyre extends StatefulHookConsumerWidget {
  const spotifyre({super.key});

  @override
  spotifyreState createState() => spotifyreState();

  static spotifyreState of(BuildContext context) =>
      context.findAncestorStateOfType<spotifyreState>()!;
}

class spotifyreState extends ConsumerState<spotifyre> {
  final logger = getLogger(spotifyre);
  SharedPreferences? localStorage;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then(((value) => localStorage = value));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode =
        ref.watch(userPreferencesProvider.select((s) => s.themeMode));
    final accentMaterialColor =
        ref.watch(userPreferencesProvider.select((s) => s.accentColorScheme));
    final isAmoledTheme =
        ref.watch(userPreferencesProvider.select((s) => s.amoledDarkTheme));
    final locale = ref.watch(userPreferencesProvider.select((s) => s.locale));
    final paletteColor =
        ref.watch(paletteProvider.select((s) => s?.dominantColor?.color));
    final router = ref.watch(routerProvider);

    ref.listen(playbackServerProvider, (_, __) {});
    ref.listen(connectServerProvider, (_, __) {});
    ref.listen(connectClientsProvider, (_, __) {});

    useDisableBatteryOptimizations();
    useInitSysTray(ref);
    useDeepLinking(ref);
    useCloseBehavior(ref);
    useGetStoragePermissions(ref);

    useEffect(() {
      FlutterNativeSplash.remove();
      return () {
        /// For enabling hot reload for audio player
        if (!kDebugMode) return;
        audioPlayer.dispose();
      };
    }, []);

    final lightTheme = useMemoized(
      () => theme(paletteColor ?? accentMaterialColor, Brightness.light, false),
      [paletteColor, accentMaterialColor],
    );
    final darkTheme = useMemoized(
      () => theme(
        paletteColor ?? accentMaterialColor,
        Brightness.dark,
        isAmoledTheme,
      ),
      [paletteColor, accentMaterialColor, isAmoledTheme],
    );

    return MaterialApp.router(
      supportedLocales: L10n.all,
      locale: locale.languageCode == "system" ? null : locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'spotifyre',
      builder: (context, child) {
        return DevicePreview.appBuilder(
          context,
          DesktopTools.platform.isDesktop && !DesktopTools.platform.isMacOS
              ? DragToResizeArea(child: child!)
              : child,
        );
      },
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      shortcuts: {
        ...WidgetsApp.defaultShortcuts.map((key, value) {
          return MapEntry(
            LogicalKeySet.fromSet(key.triggers?.toSet() ?? {}),
            value,
          );
        }),
        LogicalKeySet(LogicalKeyboardKey.space): PlayPauseIntent(ref),
        LogicalKeySet(LogicalKeyboardKey.comma, LogicalKeyboardKey.control):
            NavigationIntent(router, "/settings"),
        LogicalKeySet(
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
        ): HomeTabIntent(ref, tab: HomeTabs.browse),
        LogicalKeySet(
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
        ): HomeTabIntent(ref, tab: HomeTabs.search),
        LogicalKeySet(
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
        ): HomeTabIntent(ref, tab: HomeTabs.library),
        LogicalKeySet(
          LogicalKeyboardKey.digit4,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
        ): HomeTabIntent(ref, tab: HomeTabs.lyrics),
        LogicalKeySet(
          LogicalKeyboardKey.keyW,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
        ): CloseAppIntent(),
      },
      actions: {
        ...WidgetsApp.defaultActions,
        PlayPauseIntent: PlayPauseAction(),
        NavigationIntent: NavigationAction(),
        HomeTabIntent: HomeTabAction(),
        CloseAppIntent: CloseAppAction(),
      },
    );
  }
}
