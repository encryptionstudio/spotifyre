import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart' hide Search;
import 'package:spotifyre/models/spotify/recommendation_seeds.dart';
import 'package:spotifyre/pages/album/album.dart';
import 'package:spotifyre/pages/connect/connect.dart';
import 'package:spotifyre/pages/connect/control/control.dart';
import 'package:spotifyre/pages/getting_started/getting_started.dart';
import 'package:spotifyre/pages/home/feed/feed_section.dart';
import 'package:spotifyre/pages/home/genres/genre_playlists.dart';
import 'package:spotifyre/pages/home/genres/genres.dart';
import 'package:spotifyre/pages/home/home.dart';
import 'package:spotifyre/pages/lastfm_login/lastfm_login.dart';
import 'package:spotifyre/pages/library/playlist_generate/playlist_generate.dart';
import 'package:spotifyre/pages/library/playlist_generate/playlist_generate_result.dart';
import 'package:spotifyre/pages/lyrics/mini_lyrics.dart';
import 'package:spotifyre/pages/playlist/liked_playlist.dart';
import 'package:spotifyre/pages/playlist/playlist.dart';
import 'package:spotifyre/pages/profile/profile.dart';
import 'package:spotifyre/pages/search/search.dart';
import 'package:spotifyre/pages/settings/blacklist.dart';
import 'package:spotifyre/pages/settings/about.dart';
import 'package:spotifyre/pages/settings/logs.dart';
import 'package:spotifyre/pages/track/track.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/services/kv_store/kv_store.dart';
import 'package:spotifyre/utils/platform.dart';
import 'package:spotifyre/components/shared/spotifyre_page_route.dart';
import 'package:spotifyre/pages/artist/artist.dart';
import 'package:spotifyre/pages/library/library.dart';
import 'package:spotifyre/pages/desktop_login/login_tutorial.dart';
import 'package:spotifyre/pages/desktop_login/desktop_login.dart';
import 'package:spotifyre/pages/lyrics/lyrics.dart';
import 'package:spotifyre/pages/root/root_app.dart';
import 'package:spotifyre/pages/settings/settings.dart';
import 'package:spotifyre/pages/mobile_login/mobile_login.dart';

final rootNavigatorKey = Catcher2.navigatorKey;
final shellRouteNavigatorKey = GlobalKey<NavigatorState>();
final routerProvider = Provider((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: shellRouteNavigatorKey,
        builder: (context, state, child) => RootApp(child: child),
        routes: [
          GoRoute(
            path: "/",
            redirect: (context, state) async {
              final authNotifier = ref.read(authenticationProvider.notifier);
              final json = await authNotifier.box.get(authNotifier.cacheKey);

              if (json?["cookie"] == null &&
                  !KVStoreService.doneGettingStarted) {
                return "/getting-started";
              }

              return null;
            },
            pageBuilder: (context, state) =>
                const spotifyrePage(child: HomePage()),
            routes: [
              GoRoute(
                path: "genres",
                pageBuilder: (context, state) =>
                    const spotifyrePage(child: GenrePage()),
              ),
              GoRoute(
                path: "genre/:categoryId",
                pageBuilder: (context, state) => spotifyrePage(
                  child: GenrePlaylistsPage(
                    category: state.extra as Category,
                  ),
                ),
              ),
              GoRoute(
                path: "feeds/:feedId",
                pageBuilder: (context, state) => spotifyrePage(
                  child: HomeFeedSectionPage(
                    sectionUri: state.pathParameters["feedId"] as String,
                  ),
                ),
              )
            ],
          ),
          GoRoute(
            path: "/search",
            name: "Search",
            pageBuilder: (context, state) =>
                const spotifyrePage(child: SearchPage()),
          ),
          GoRoute(
              path: "/library",
              name: "Library",
              pageBuilder: (context, state) =>
                  const spotifyrePage(child: LibraryPage()),
              routes: [
                GoRoute(
                    path: "generate",
                    pageBuilder: (context, state) =>
                        const spotifyrePage(child: PlaylistGeneratorPage()),
                    routes: [
                      GoRoute(
                        path: "result",
                        pageBuilder: (context, state) => spotifyrePage(
                          child: PlaylistGenerateResultPage(
                            state: state.extra as GeneratePlaylistProviderInput,
                          ),
                        ),
                      ),
                    ]),
              ]),
          GoRoute(
            path: "/lyrics",
            name: "Lyrics",
            pageBuilder: (context, state) =>
                const spotifyrePage(child: LyricsPage()),
          ),
          GoRoute(
            path: "/settings",
            pageBuilder: (context, state) => const spotifyrePage(
              child: SettingsPage(),
            ),
            routes: [
              GoRoute(
                path: "blacklist",
                pageBuilder: (context, state) => spotifyreSlidePage(
                  child: const BlackListPage(),
                ),
              ),
              if (!kIsWeb)
                GoRoute(
                  path: "logs",
                  pageBuilder: (context, state) => spotifyreSlidePage(
                    child: const LogsPage(),
                  ),
                ),
              GoRoute(
                path: "about",
                pageBuilder: (context, state) => spotifyreSlidePage(
                  child: const Aboutspotifyre(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: "/album/:id",
            pageBuilder: (context, state) {
              assert(state.extra is AlbumSimple);
              return spotifyrePage(
                child: AlbumPage(album: state.extra as AlbumSimple),
              );
            },
          ),
          GoRoute(
            path: "/artist/:id",
            pageBuilder: (context, state) {
              assert(state.pathParameters["id"] != null);
              return spotifyrePage(
                  child: ArtistPage(state.pathParameters["id"]!));
            },
          ),
          GoRoute(
            path: "/playlist/:id",
            pageBuilder: (context, state) {
              assert(state.extra is PlaylistSimple);
              return spotifyrePage(
                child: state.pathParameters["id"] == "user-liked-tracks"
                    ? LikedPlaylistPage(playlist: state.extra as PlaylistSimple)
                    : PlaylistPage(playlist: state.extra as PlaylistSimple),
              );
            },
          ),
          GoRoute(
            path: "/track/:id",
            pageBuilder: (context, state) {
              final id = state.pathParameters["id"]!;
              return spotifyrePage(
                child: TrackPage(trackId: id),
              );
            },
          ),
          GoRoute(
            path: "/connect",
            pageBuilder: (context, state) => const spotifyrePage(
              child: ConnectPage(),
            ),
            routes: [
              GoRoute(
                path: "control",
                pageBuilder: (context, state) {
                  return const spotifyrePage(
                    child: ConnectControlPage(),
                  );
                },
              )
            ],
          ),
          GoRoute(
            path: "/profile",
            pageBuilder: (context, state) =>
                const spotifyrePage(child: ProfilePage()),
          )
        ],
      ),
      GoRoute(
        path: "/mini-player",
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => spotifyrePage(
          child: MiniLyricsPage(prevSize: state.extra as Size),
        ),
      ),
      GoRoute(
        path: "/getting-started",
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const spotifyrePage(
          child: GettingStarting(),
        ),
      ),
      GoRoute(
        path: "/login",
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => spotifyrePage(
          child: kIsMobile ? const WebViewLogin() : const DesktopLoginPage(),
        ),
      ),
      GoRoute(
        path: "/login-tutorial",
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const spotifyrePage(
          child: LoginTutorial(),
        ),
      ),
      GoRoute(
        path: "/lastfm-login",
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const spotifyrePage(child: LastFMLoginPage()),
      ),
    ],
  );
});
