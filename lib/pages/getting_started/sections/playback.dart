import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotifyre/collections/assets.gen.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/getting_started/blur_card.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/extensions/string.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_state.dart';

final audioSourceToIconMap = {
  AudioSource.youtube: const Icon(
    spotifyreIcons.youtube,
    color: Colors.red,
    size: 30,
  ),
  AudioSource.piped: const Icon(spotifyreIcons.piped, size: 30),
  AudioSource.jiosaavn: Assets.jiosaavn.image(width: 48, height: 48),
};

class GettingStartedPagePlaybackSection extends HookConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const GettingStartedPagePlaybackSection({
    super.key,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, ref) {
    final ThemeData(:textTheme, :colorScheme, :dividerColor) =
        Theme.of(context);
    final preferences = ref.watch(userPreferencesProvider);
    final preferencesNotifier = ref.read(userPreferencesProvider.notifier);

    final audioSourceToDescription = useMemoized(
        () => {
              AudioSource.youtube: "${context.l10n.youtube_source_description}\n"
                  "${context.l10n.highest_quality("148kbps mp4, 128kbps opus")}",
              AudioSource.piped: context.l10n.piped_source_description,
              AudioSource.jiosaavn:
                  "${context.l10n.jiosaavn_source_description}\n"
                      "${context.l10n.highest_quality("320kbps mp")}",
            },
        []);

    return Center(
      child: BlurCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(spotifyreIcons.album, size: 16),
                const Gap(8),
                Text(context.l10n.playback, style: textTheme.titleMedium),
              ],
            ),
            const Gap(16),
            ListTile(
              title: Text(
                context.l10n.select_audio_source,
                style: textTheme.titleMedium,
              ),
            ),
            const Gap(16),
            ToggleButtons(
              isSelected: [
                for (final source in AudioSource.values)
                  preferences.audioSource == source,
              ],
              onPressed: (index) {
                preferencesNotifier.setAudioSource(AudioSource.values[index]);
              },
              borderRadius: BorderRadius.circular(8),
              children: [
                for (final source in AudioSource.values)
                  SizedBox.square(
                    dimension: 84,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        audioSourceToIconMap[source]!,
                        const Gap(8),
                        Text(
                          source.name.capitalize(),
                          style: textTheme.bodySmall!.copyWith(
                            color: preferences.audioSource == source
                                ? colorScheme.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            ListTile(
              title: Align(
                alignment: switch (preferences.audioSource) {
                  AudioSource.youtube => Alignment.centerLeft,
                  AudioSource.piped => Alignment.center,
                  AudioSource.jiosaavn => Alignment.centerRight,
                },
                child: Text(
                  audioSourceToDescription[preferences.audioSource]!,
                  style: textTheme.bodySmall?.copyWith(
                    color: dividerColor,
                  ),
                ),
              ),
            ),
            const Gap(16),
            ListTile(
              title: Text(context.l10n.endless_playback),
              subtitle: Text(
                context.l10n.endless_playback_description,
                style: textTheme.bodySmall?.copyWith(
                  color: dividerColor,
                ),
              ),
              onTap: () {
                preferencesNotifier
                    .setEndlessPlayback(!preferences.endlessPlayback);
              },
              trailing: Switch(
                value: preferences.endlessPlayback,
                onChanged: (value) {
                  preferencesNotifier.setEndlessPlayback(value);
                },
              ),
            ),
            const Gap(34),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.icon(
                  icon: const Icon(spotifyreIcons.angleLeft),
                  label: Text(context.l10n.previous),
                  onPressed: onPrevious,
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: FilledButton.icon(
                    icon: const Icon(spotifyreIcons.angleRight),
                    label: Text(context.l10n.next),
                    onPressed: onNext,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
