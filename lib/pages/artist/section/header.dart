import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotifyre/collections/fake.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/extensions/constrains.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/hooks/utils/use_breakpoint_value.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/blacklist_provider.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';
import 'package:spotifyre/utils/primitive_utils.dart';

class ArtistPageHeader extends HookConsumerWidget {
  final String artistId;
  const ArtistPageHeader({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, ref) {
    final artistQuery = ref.watch(artistProvider(artistId));
    final artist = artistQuery.asData?.value ?? FakeData.artist;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final ThemeData(:textTheme) = theme;

    final chipTextVariant = useBreakpointValue(
      xs: textTheme.bodySmall,
      sm: textTheme.bodySmall,
      md: textTheme.bodyMedium,
      lg: textTheme.bodyLarge,
      xl: textTheme.titleSmall,
      xxl: textTheme.titleMedium,
    );

    final auth = ref.watch(authenticationProvider);
    final blacklist = ref.watch(blacklistProvider);
    final isBlackListed = blacklist.contains(
      BlacklistedElement.artist(artistId, artist.name!),
    );

    final image = artist.images.asUrlString(
      placeholder: ImagePlaceholder.artist,
    );

    return LayoutBuilder(
      builder: (context, constrains) {
        return Center(
          child: Flex(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: constrains.smAndDown
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            direction: constrains.smAndDown ? Axis.vertical : Axis.horizontal,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: kElevationToShadow[2],
                  borderRadius: BorderRadius.circular(35),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: UniversalImage(
                    path: image,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Gap(20),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(50)),
                        child: Skeleton.keep(
                          child: Text(
                            artist.type!.toUpperCase(),
                            style: chipTextVariant.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isBlackListed) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: Colors.red[400],
                              borderRadius: BorderRadius.circular(50)),
                          child: Text(
                            context.l10n.blacklisted,
                            style: chipTextVariant.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  Text(
                    artist.name!,
                    style: mediaQuery.smAndDown
                        ? textTheme.headlineSmall
                        : textTheme.headlineMedium,
                  ),
                  Text(
                    context.l10n.followers(
                      PrimitiveUtils.toReadableNumber(
                        artist.followers!.total!.toDouble(),
                      ),
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: mediaQuery.mdAndUp ? FontWeight.bold : null,
                    ),
                  ),
                  const Gap(20),
                  Skeleton.keep(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (auth != null)
                          Consumer(
                            builder: (context, ref, _) {
                              final isFollowingQuery = ref
                                  .watch(artistIsFollowingProvider(artist.id!));
                              final followingArtistNotifier =
                                  ref.watch(followedArtistsProvider.notifier);

                              return switch (isFollowingQuery) {
                                AsyncData(value: final following) => Builder(
                                    builder: (context) {
                                      if (following) {
                                        return OutlinedButton(
                                          onPressed: () async {
                                            await followingArtistNotifier
                                                .removeArtists([artist.id!]);
                                          },
                                          child: Text(context.l10n.following),
                                        );
                                      }

                                      return FilledButton(
                                        onPressed: () async {
                                          await followingArtistNotifier
                                              .saveArtists([artist.id!]);
                                        },
                                        child: Text(context.l10n.follow),
                                      );
                                    },
                                  ),
                                AsyncError() => const SizedBox(),
                                _ => const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(),
                                  )
                              };
                            },
                          ),
                        const SizedBox(width: 5),
                        IconButton(
                          tooltip: context.l10n.add_artist_to_blacklist,
                          icon: Icon(
                            spotifyreIcons.userRemove,
                            color:
                                !isBlackListed ? Colors.red[400] : Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                isBlackListed ? Colors.red[400] : null,
                          ),
                          onPressed: () async {
                            if (isBlackListed) {
                              ref.read(blacklistProvider.notifier).remove(
                                    BlacklistedElement.artist(
                                        artist.id!, artist.name!),
                                  );
                            } else {
                              ref.read(blacklistProvider.notifier).add(
                                    BlacklistedElement.artist(
                                        artist.id!, artist.name!),
                                  );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(spotifyreIcons.share),
                          onPressed: () async {
                            if (artist.externalUrls?.spotify != null) {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: artist.externalUrls!.spotify!,
                                ),
                              );
                            }

                            if (!context.mounted) return;

                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                width: 300,
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  context.l10n.artist_url_copied,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
