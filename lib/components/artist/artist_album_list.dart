import 'package:flutter/material.dart' hide Page;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/components/shared/horizontal_playbutton_card_view/horizontal_playbutton_card_view.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/models/logger.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';

class ArtistAlbumList extends HookConsumerWidget {
  final String artistId;
  ArtistAlbumList(
    this.artistId, {
    super.key,
  });

  final logger = getLogger(ArtistAlbumList);

  @override
  Widget build(BuildContext context, ref) {
    final albumsQuery = ref.watch(artistAlbumsProvider(artistId));
    final albumsQueryNotifier =
        ref.watch(artistAlbumsProvider(artistId).notifier);

    final albums = albumsQuery.asData?.value.items ?? [];

    final theme = Theme.of(context);

    return HorizontalPlaybuttonCardView<Album>(
      isLoadingNextPage: albumsQuery.isLoadingNextPage,
      hasNextPage: albumsQuery.asData?.value.hasMore ?? false,
      items: albums,
      onFetchMore: albumsQueryNotifier.fetchMore,
      title: Text(
        context.l10n.albums,
        style: theme.textTheme.headlineSmall,
      ),
    );
  }
}
