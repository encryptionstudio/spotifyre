import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/shared/dialogs/select_device_dialog.dart';
import 'package:spotifyre/components/shared/tracks_view/track_view_props.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/models/connect/connect.dart';
import 'package:spotifyre/provider/connect/connect.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist_provider.dart';
import 'package:spotifyre/services/audio_player/audio_player.dart';

class TrackViewHeaderButtons extends HookConsumerWidget {
  final PaletteColor color;
  final bool compact;
  const TrackViewHeaderButtons({
    super.key,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, ref) {
    final props = InheritedTrackView.of(context);
    final playlist = ref.watch(proxyPlaylistProvider);
    final playlistNotifier = ref.watch(proxyPlaylistProvider.notifier);

    final isActive = playlist.collections.contains(props.collectionId);

    final isLoading = useState(false);

    const progressIndicator = Center(
      child: SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: .8),
      ),
    );

    void onShuffle() async {
      try {
        isLoading.value = true;

        final allTracks = await props.pagination.onFetchAll();

        if (!context.mounted) return;

        final isRemoteDevice = await showSelectDeviceDialog(context, ref);
        if (isRemoteDevice) {
          final remotePlayback = ref.read(connectProvider.notifier);
          await remotePlayback.load(
            WebSocketLoadEventData(
                tracks: allTracks,
                collectionId: props.collectionId,
                initialIndex: Random().nextInt(allTracks.length)),
          );
          await remotePlayback.setShuffle(true);
        } else {
          await playlistNotifier.load(
            allTracks,
            autoPlay: true,
            initialIndex: Random().nextInt(allTracks.length),
          );
          await audioPlayer.setShuffle(true);
          playlistNotifier.addCollection(props.collectionId);
        }
      } finally {
        isLoading.value = false;
      }
    }

    void onPlay() async {
      try {
        isLoading.value = true;

        final allTracks = await props.pagination.onFetchAll();

        if (!context.mounted) return;

        final isRemoteDevice = await showSelectDeviceDialog(context, ref);
        if (isRemoteDevice) {
          final remotePlayback = ref.read(connectProvider.notifier);
          await remotePlayback.load(
            WebSocketLoadEventData(
              tracks: allTracks,
              collectionId: props.collectionId,
            ),
          );
        } else {
          await playlistNotifier.load(allTracks, autoPlay: true);
          playlistNotifier.addCollection(props.collectionId);
        }
      } finally {
        isLoading.value = false;
      }
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isActive && !isLoading.value)
            IconButton(
              icon: const Icon(spotifyreIcons.shuffle),
              onPressed: props.tracks.isEmpty ? null : onShuffle,
            ),
          const Gap(10),
          IconButton.filledTonal(
            icon: isActive
                ? const Icon(spotifyreIcons.pause)
                : isLoading.value
                    ? progressIndicator
                    : const Icon(spotifyreIcons.play),
            onPressed: isActive || props.tracks.isEmpty || isLoading.value
                ? null
                : onPlay,
          ),
          const Gap(10),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isActive || isLoading.value ? 0 : 1,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: SizedBox.square(
              dimension: isActive || isLoading.value ? 0 : null,
              child: FilledButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(150, 40)),
                label: Text(context.l10n.shuffle),
                icon: const Icon(spotifyreIcons.shuffle),
                onPressed: props.tracks.isEmpty ? null : onShuffle,
              ),
            ),
          ),
        ),
        const Gap(10),
        FilledButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: color.color,
              foregroundColor: color.bodyTextColor,
              minimumSize: const Size(150, 40)),
          onPressed: isActive || props.tracks.isEmpty || isLoading.value
              ? null
              : onPlay,
          icon: isActive
              ? const Icon(spotifyreIcons.pause)
              : isLoading.value
                  ? progressIndicator
                  : const Icon(spotifyreIcons.play),
          label: Text(context.l10n.play),
        ),
      ],
    );
  }
}
