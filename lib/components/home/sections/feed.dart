import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/shared/horizontal_playbutton_card_view/horizontal_playbutton_card_view.dart';
import 'package:spotifyre/provider/spotify/views/home.dart';
import 'package:spotifyre/utils/service_utils.dart';

class HomePageFeedSection extends HookConsumerWidget {
  const HomePageFeedSection({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final homeFeed = ref.watch(homeViewProvider);
    final nonShortSections = homeFeed.asData?.value?.sections
            .where((s) => s.typename == "HomeGenericSectionData")
            .toList() ??
        [];

    return SliverList.builder(
      itemCount: nonShortSections.length,
      itemBuilder: (context, index) {
        final section = nonShortSections[index];
        if (section.items.isEmpty) return const SizedBox.shrink();

        return HorizontalPlaybuttonCardView(
          items: [
            for (final item in section.items)
              if (item.album != null)
                item.album!.asAlbum
              else if (item.artist != null)
                item.artist!.asArtist
              else if (item.playlist != null)
                item.playlist!.asPlaylist
          ],
          title: Text(section.title ?? "No Titel"),
          hasNextPage: false,
          isLoadingNextPage: false,
          onFetchMore: () {},
          titleTrailing: Directionality(
            textDirection: TextDirection.rtl,
            child: TextButton.icon(
              label: const Text("Browse More"),
              icon: const Icon(spotifyreIcons.angleRight),
              onPressed: () =>
                  ServiceUtils.push(context, "/feeds/${section.uri}"),
            ),
          ),
        );
      },
    );
  }
}
