import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/components/shared/tracks_view/track_view.dart';
import 'package:spotifyre/components/shared/tracks_view/track_view_props.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';

class LikedPlaylistPage extends HookConsumerWidget {
  final PlaylistSimple playlist;
  const LikedPlaylistPage({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, ref) {
    final likedTracks = ref.watch(likedTracksProvider);
    final tracks = likedTracks.asData?.value ?? <Track>[];

    return InheritedTrackView(
      collectionId: playlist.id!,
      image: "assets/liked-tracks.jpg",
      pagination: PaginationProps(
        hasNextPage: false,
        isLoading: false,
        onFetchMore: () {},
        onFetchAll: () async {
          return tracks.toList();
        },
        onRefresh: () async {
          ref.invalidate(likedTracksProvider);
        },
      ),
      title: playlist.name!,
      description: playlist.description,
      tracks: tracks,
      routePath: '/playlist/${playlist.id}',
      isLiked: false,
      shareUrl: "",
      onHeart: null,
      child: const TrackView(),
    );
  }
}
