import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/components/shared/links/artist_link.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/provider/download_manager_provider.dart';
import 'package:spotifyre/services/download_manager/download_status.dart';
import 'package:spotifyre/services/sourced_track/sourced_track.dart';

class DownloadItem extends HookConsumerWidget {
  final Track track;
  const DownloadItem({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context, ref) {
    final downloadManager = ref.watch(downloadManagerProvider);

    final taskStatus = useState<DownloadStatus?>(null);

    useEffect(() {
      if (track is! SourcedTrack) return null;
      final notifier = downloadManager.getStatusNotifier(track as SourcedTrack);

      taskStatus.value = notifier?.value;

      void listener() {
        taskStatus.value = notifier?.value;
      }

      notifier?.addListener(listener);

      return () {
        notifier?.removeListener(listener);
      };
    }, [track]);

    final isQueryingSourceInfo =
        taskStatus.value == null || track is! SourcedTrack;

    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: UniversalImage(
            height: 40,
            width: 40,
            path: (track.album?.images).asUrlString(
              placeholder: ImagePlaceholder.albumArt,
            ),
          ),
        ),
      ),
      title: Text(track.name ?? ''),
      subtitle: ArtistLink(
        artists: track.artists ?? <Artist>[],
        mainAxisAlignment: WrapAlignment.start,
      ),
      trailing: isQueryingSourceInfo
          ? Text(
              context.l10n.querying_info,
              style: Theme.of(context).textTheme.labelMedium,
            )
          : switch (taskStatus.value!) {
              DownloadStatus.downloading => HookBuilder(builder: (context) {
                  final taskProgress = useListenable(useMemoized(
                    () => downloadManager
                        .getProgressNotifier(track as SourcedTrack),
                    [track],
                  ));
                  return SizedBox(
                    width: 140,
                    child: Row(
                      children: [
                        CircularProgressIndicator(
                          value: taskProgress?.value ?? 0,
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                            icon: const Icon(spotifyreIcons.pause),
                            onPressed: () {
                              downloadManager.pause(track as SourcedTrack);
                            }),
                        const SizedBox(width: 10),
                        IconButton(
                            icon: const Icon(spotifyreIcons.close),
                            onPressed: () {
                              downloadManager.cancel(track as SourcedTrack);
                            }),
                      ],
                    ),
                  );
                }),
              DownloadStatus.paused => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(spotifyreIcons.play),
                        onPressed: () {
                          downloadManager.resume(track as SourcedTrack);
                        }),
                    const SizedBox(width: 10),
                    IconButton(
                        icon: const Icon(spotifyreIcons.close),
                        onPressed: () {
                          downloadManager.cancel(track as SourcedTrack);
                        })
                  ],
                ),
              DownloadStatus.failed || DownloadStatus.canceled => SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      Icon(
                        spotifyreIcons.error,
                        color: Colors.red[400],
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(spotifyreIcons.refresh),
                        onPressed: () {
                          downloadManager.retry(track as SourcedTrack);
                        },
                      ),
                    ],
                  ),
                ),
              DownloadStatus.completed =>
                Icon(spotifyreIcons.done, color: Colors.green[400]),
              DownloadStatus.queued => IconButton(
                  icon: const Icon(spotifyreIcons.close),
                  onPressed: () {
                    downloadManager.removeFromQueue(track as SourcedTrack);
                  }),
            },
    );
  }
}
