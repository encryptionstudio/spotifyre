import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/components/shared/tracks_view/track_view.dart';
import 'package:spotifyre/components/shared/tracks_view/track_view_props.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';

class AlbumPage extends HookConsumerWidget {
  final AlbumSimple album;
  const AlbumPage({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context, ref) {
    final tracks = ref.watch(albumTracksProvider(album));
    final tracksNotifier = ref.watch(albumTracksProvider(album).notifier);
    final favoriteAlbumsNotifier = ref.watch(favoriteAlbumsProvider.notifier);
    final isSavedAlbum = ref.watch(albumsIsSavedProvider(album.id!));

    return InheritedTrackView(
      collectionId: album.id!,
      image: album.images.asUrlString(
        placeholder: ImagePlaceholder.albumArt,
      ),
      title: album.name!,
      description:
          "${context.l10n.released} • ${album.releaseDate} • ${album.artists!.first.name}",
      tracks: tracks.asData?.value.items ?? [],
      pagination: PaginationProps(
        hasNextPage: tracks.asData?.value.hasMore ?? false,
        isLoading: tracks.isLoadingNextPage,
        onFetchMore: () async {
          await tracksNotifier.fetchMore();
        },
        onFetchAll: () async {
          return tracksNotifier.fetchAll();
        },
        onRefresh: () async {
          ref.invalidate(albumTracksProvider(album));
        },
      ),
      routePath: "/album/${album.id}",
      shareUrl: album.externalUrls!.spotify!,
      isLiked: isSavedAlbum.asData?.value ?? false,
      onHeart: isSavedAlbum.asData?.value == null
          ? null
          : () async {
              if (isSavedAlbum.asData!.value) {
                await favoriteAlbumsNotifier.removeFavorites([album.id!]);
              } else {
                await favoriteAlbumsNotifier.addFavorites([album.id!]);
              }
              return null;
            },
      child: const TrackView(),
    );
  }
}
