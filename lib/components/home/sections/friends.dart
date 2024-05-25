import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotifyre/collections/fake.dart';
import 'package:spotifyre/components/home/sections/friends/friend_item.dart';
import 'package:spotifyre/hooks/utils/use_breakpoint_value.dart';
import 'package:spotifyre/models/spotify_friends.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';

class HomePageFriendsSection extends HookConsumerWidget {
  const HomePageFriendsSection({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final friendsQuery = ref.watch(friendsProvider);
    final friends =
        friendsQuery.asData?.value.friends ?? FakeData.friends.friends;

    final groupCount = useBreakpointValue(
      sm: 3,
      xs: 2,
      md: 4,
      lg: 5,
      xl: 6,
      xxl: 7,
    );

    final friendGroup = friends.fold<List<List<SpotifyFriendActivity>>>(
      [],
      (previousValue, element) {
        if (previousValue.isEmpty) {
          return [
            [element]
          ];
        }

        final lastGroup = previousValue.last;
        if (lastGroup.length < groupCount) {
          return [
            ...previousValue.sublist(0, previousValue.length - 1),
            [...lastGroup, element]
          ];
        }

        return [
          ...previousValue,
          [element]
        ];
      },
    );

    if (friendsQuery.isLoading ||
        friendsQuery.asData?.value.friends.isEmpty == true) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      );
    }

    return Skeletonizer.sliver(
      enabled: friendsQuery.isLoading,
      child: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Friends',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: PointerDeviceKind.values.toSet(),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in friendGroup)
                      Row(
                        children: [
                          for (final friend in group)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FriendItem(friend: friend),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
