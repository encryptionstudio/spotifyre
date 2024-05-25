import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';

import 'package:spotifyre/collections/assets.gen.dart';
import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/components/shared/links/artist_link.dart';
import 'package:spotifyre/components/shared/links/link_text.dart';
import 'package:spotifyre/extensions/artist_simple.dart';
import 'package:spotifyre/extensions/constrains.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/utils/service_utils.dart';

class PlayerTrackDetails extends HookConsumerWidget {
  final Color? color;
  final Track? track;
  const PlayerTrackDetails({super.key, this.color, this.track});

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final playback = ref.watch(proxyPlaylistProvider);

    return Row(
      children: [
        if (playback.activeTrack != null)
          Container(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(
              maxWidth: 80,
              maxHeight: 80,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: UniversalImage(
                path: (track?.album?.images)
                    .asUrlString(placeholder: ImagePlaceholder.albumArt),
                placeholder: Assets.albumPlaceholder.path,
              ),
            ),
          ),
        if (mediaQuery.mdAndDown)
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinkText(
                  playback.activeTrack?.name ?? "",
                  "/track/${playback.activeTrack?.id}",
                  push: true,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  playback.activeTrack?.artists?.asString() ?? "",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall!.copyWith(color: color),
                )
              ],
            ),
          ),
        if (mediaQuery.lgAndUp)
          Flexible(
            flex: 1,
            child: Column(
              children: [
                LinkText(
                  playback.activeTrack?.name ?? "",
                  "/track/${playback.activeTrack?.id}",
                  push: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                ArtistLink(
                  artists: playback.activeTrack?.artists ?? [],
                  onRouteChange: (route) {
                    ServiceUtils.push(context, route);
                  },
                )
              ],
            ),
          ),
      ],
    );
  }
}
