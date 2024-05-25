import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotify/spotify.dart' hide Offset;
import 'package:spotifyre/collections/fake.dart';
import 'package:spotifyre/components/playlist/playlist_card.dart';
import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/components/shared/page_window_title_bar.dart';
import 'package:spotifyre/components/shared/waypoint.dart';
import 'package:spotifyre/extensions/constrains.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';
import 'package:collection/collection.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';

class GenrePlaylistsPage extends HookConsumerWidget {
  final Category category;
  const GenrePlaylistsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, ref) {
    final mediaQuery = MediaQuery.of(context);
    final playlists = ref.watch(categoryPlaylistsProvider(category.id!));
    final playlistsNotifier =
        ref.read(categoryPlaylistsProvider(category.id!).notifier);
    final scrollController = useScrollController();

    return Scaffold(
      appBar: DesktopTools.platform.isDesktop
          ? const PageWindowTitleBar(
              leading: BackButton(color: Colors.white),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            )
          : null,
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: UniversalImage.imageProvider(category.icons!.first.url!),
            alignment: Alignment.topCenter,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
            repeat: ImageRepeat.noRepeat,
            matchTextDirection: true,
          ),
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: DesktopTools.platform.isMobile,
              expandedHeight: mediaQuery.mdAndDown ? 200 : 150,
              title: const Text(""),
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: DesktopTools.platform.isDesktop,
                title: Text(
                  category.name!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      const Shadow(
                        offset: Offset(-1.5, -1.5),
                        color: Colors.black54,
                      ),
                      const Shadow(
                        offset: Offset(1.5, -1.5),
                        color: Colors.black54,
                      ),
                      const Shadow(
                        offset: Offset(1.5, 1.5),
                        color: Colors.black54,
                      ),
                      const Shadow(
                        offset: Offset(-1.5, 1.5),
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                collapseMode: CollapseMode.parallax,
              ),
            ),
            const SliverGap(20),
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: mediaQuery.mdAndDown ? 12 : 24,
                ),
                sliver: playlists.asData?.value.items.isNotEmpty != true
                    ? Skeletonizer.sliver(
                        child: SliverToBoxAdapter(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(
                              6,
                              (index) => PlaylistCard(FakeData.playlist),
                            ),
                          ),
                        ),
                      )
                    : SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 190,
                          mainAxisExtent: mediaQuery.mdAndDown ? 225 : 250,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount:
                            (playlists.asData?.value.items.length ?? 0) + 1,
                        itemBuilder: (context, index) {
                          final playlist = playlists.asData?.value.items
                              .elementAtOrNull(index);

                          if (playlist == null) {
                            if (playlists.asData?.value.hasMore == false) {
                              return const SizedBox.shrink();
                            }
                            return Skeletonizer(
                              enabled: true,
                              child: Waypoint(
                                controller: scrollController,
                                isGrid: true,
                                onTouchEdge: playlistsNotifier.fetchMore,
                                child: PlaylistCard(FakeData.playlist),
                              ),
                            );
                          }

                          return Skeleton.keep(
                            child: PlaylistCard(playlist),
                          );
                        },
                      ),
              ),
            ),
            const SliverGap(20),
          ],
        ),
      ),
    );
  }
}
