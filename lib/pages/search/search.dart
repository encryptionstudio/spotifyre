import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:spotify/spotify.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/shared/inter_scrollbar/inter_scrollbar.dart';
import 'package:spotifyre/components/shared/fallbacks/anonymous_fallback.dart';
import 'package:spotifyre/components/shared/page_window_title_bar.dart';
import 'package:spotifyre/extensions/constrains.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/hooks/utils/use_force_update.dart';
import 'package:spotifyre/pages/search/sections/albums.dart';
import 'package:spotifyre/pages/search/sections/artists.dart';
import 'package:spotifyre/pages/search/sections/playlists.dart';
import 'package:spotifyre/pages/search/sections/tracks.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';
import 'package:spotifyre/services/kv_store/kv_store.dart';

import 'package:spotifyre/utils/platform.dart';

class SearchPage extends HookConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);
    final searchTerm = ref.watch(searchTermStateProvider);
    final controller = useSearchController();

    ref.watch(authenticationProvider);
    final authenticationNotifier = ref.watch(authenticationProvider.notifier);
    final mediaQuery = MediaQuery.of(context);

    final searchTrack = ref.watch(searchProvider(SearchType.track));
    final searchAlbum = ref.watch(searchProvider(SearchType.album));
    final searchPlaylist = ref.watch(searchProvider(SearchType.playlist));
    final searchArtist = ref.watch(searchProvider(SearchType.artist));

    final queries = [searchTrack, searchAlbum, searchPlaylist, searchArtist];

    final isFetching = queries.every((s) => s.isLoading);

    useEffect(() {
      controller.text = searchTerm;

      return null;
    }, []);

    final resultWidget = HookBuilder(
      builder: (context) {
        final controller = useScrollController();

        return InterScrollbar(
          controller: controller,
          child: SingleChildScrollView(
            controller: controller,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchTracksSection(),
                    SearchPlaylistsSection(),
                    Gap(20),
                    SearchArtistsSection(),
                    Gap(20),
                    SearchAlbumsSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return SafeArea(
      bottom: false,
      child: Scaffold(
        appBar: kIsDesktop && !kIsMacOS ? const PageWindowTitleBar() : null,
        body: !authenticationNotifier.isLoggedIn
            ? const AnonymousFallback()
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    color: theme.scaffoldBackgroundColor,
                    child: SearchAnchor(
                      searchController: controller,
                      viewBuilder: (_) => HookBuilder(builder: (context) {
                        final searchController = useListenable(controller);
                        final update = useForceUpdate();
                        final suggestions = searchController.text.isEmpty
                            ? KVStoreService.recentSearches
                            : KVStoreService.recentSearches
                                .where(
                                  (s) =>
                                      weightedRatio(
                                        s.toLowerCase(),
                                        searchController.text.toLowerCase(),
                                      ) >
                                      50,
                                )
                                .toList();

                        return ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];

                            return ListTile(
                              leading: const Icon(spotifyreIcons.history),
                              title: Text(suggestion),
                              trailing: IconButton(
                                icon: const Icon(spotifyreIcons.trash),
                                onPressed: () {
                                  KVStoreService.setRecentSearches(
                                    KVStoreService.recentSearches
                                        .where((s) => s != suggestion)
                                        .toList(),
                                  );
                                  update();
                                },
                              ),
                              onTap: () {
                                controller.closeView(suggestion);
                                ref
                                    .read(searchTermStateProvider.notifier)
                                    .state = suggestion;
                              },
                            );
                          },
                        );
                      }),
                      suggestionsBuilder: (context, controller) {
                        return [];
                      },
                      viewOnSubmitted: (value) async {
                        controller.closeView(value);
                        Timer(
                          const Duration(milliseconds: 50),
                          () {
                            ref.read(searchTermStateProvider.notifier).state =
                                value;
                            if (value.trim().isEmpty) {
                              return;
                            }
                            KVStoreService.setRecentSearches(
                              {
                                value,
                                ...KVStoreService.recentSearches,
                              }.toList(),
                            );
                          },
                        );
                      },
                      builder: (context, controller) {
                        return SearchBar(
                          autoFocus: queries.none((s) =>
                                  s.asData?.value != null && !s.hasError) &&
                              !kIsMobile,
                          controller: controller,
                          leading: const Icon(spotifyreIcons.search),
                          hintText: "${context.l10n.search}...",
                          onTap: controller.openView,
                          onChanged: (_) => controller.openView(),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: searchTerm.isEmpty
                          ? Column(
                              children: [
                                SizedBox(
                                  height: mediaQuery.size.height * 0.2,
                                ),
                                Icon(
                                  spotifyreIcons.web,
                                  size: 120,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.7),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  context.l10n.search_to_get_results,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            )
                          : isFetching
                              ? Container(
                                  constraints: BoxConstraints(
                                    maxWidth: mediaQuery.lgAndUp
                                        ? mediaQuery.size.width * 0.5
                                        : mediaQuery.size.width,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        context.l10n.crunching_results,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.onBackground
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const LinearProgressIndicator(),
                                    ],
                                  ),
                                )
                              : resultWidget,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
