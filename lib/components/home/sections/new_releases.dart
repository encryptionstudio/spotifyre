import 'package:flutter/material.dart' hide Page;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/components/shared/horizontal_playbutton_card_view/horizontal_playbutton_card_view.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';

class HomeNewReleasesSection extends HookConsumerWidget {
  const HomeNewReleasesSection({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final auth = ref.watch(authenticationProvider);

    final newReleases = ref.watch(albumReleasesProvider);
    final newReleasesNotifier = ref.read(albumReleasesProvider.notifier);

    final albums = ref.watch(userArtistAlbumReleasesProvider);

    if (auth == null ||
        newReleases.isLoading ||
        newReleases.asData?.value.items.isEmpty == true) {
      return const SizedBox.shrink();
    }

    return HorizontalPlaybuttonCardView<Album>(
      items: albums,
      title: Text(context.l10n.new_releases),
      isLoadingNextPage: newReleases.isLoadingNextPage,
      hasNextPage: newReleases.asData?.value.hasMore ?? false,
      onFetchMore: newReleasesNotifier.fetchMore,
    );
  }
}
