import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';

import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/extensions/image.dart';

class SimpleTrackTile extends HookWidget {
  final Track track;
  final VoidCallback? onDelete;
  const SimpleTrackTile({
    super.key,
    required this.track,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: UniversalImage(
          path: (track.album?.images).asUrlString(
            placeholder: ImagePlaceholder.artist,
          ),
          height: 40,
          width: 40,
        ),
      ),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(track.name!),
      trailing: onDelete == null
          ? null
          : IconButton(
              icon: const Icon(spotifyreIcons.close),
              onPressed: onDelete,
            ),
      subtitle: Text(
        track.artists?.map((e) => e.name).join(", ") ?? track.album?.name ?? "",
      ),
    );
  }
}
