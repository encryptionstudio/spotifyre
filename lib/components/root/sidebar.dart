import 'package:collection/collection.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

import 'package:spotifyre/collections/assets.gen.dart';
import 'package:spotifyre/collections/side_bar_tiles.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/connect/connect_device.dart';
import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/extensions/constrains.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/hooks/utils/use_brightness_value.dart';
import 'package:spotifyre/hooks/controllers/use_sidebarx_controller.dart';
import 'package:spotifyre/provider/download_manager_provider.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';

import 'package:spotifyre/provider/user_preferences/user_preferences_provider.dart';
import 'package:spotifyre/provider/user_preferences/user_preferences_state.dart';
import 'package:spotifyre/utils/platform.dart';
import 'package:spotifyre/utils/service_utils.dart';

class Sidebar extends HookConsumerWidget {
  final int? selectedIndex;
  final void Function(int) onSelectedIndexChanged;
  final Widget child;

  const Sidebar({
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.child,
    super.key,
  });

  static Widget brandLogo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Assets.spotifyreLogoPng.image(height: 50),
    );
  }

  static void goToSettings(BuildContext context) {
    GoRouter.of(context).go("/settings");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);

    final downloadCount = ref.watch(downloadManagerProvider).$downloadCount;

    final layoutMode =
        ref.watch(userPreferencesProvider.select((s) => s.layoutMode));

    final controller = useSidebarXController(
      selectedIndex: selectedIndex ?? 0,
      extended: mediaQuery.lgAndUp,
    );

    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceVariant;

    final bgColor = useBrightnessValue(
      Color.lerp(bg, Colors.white, 0.7),
      Color.lerp(bg, Colors.black, 0.45)!,
    );

    final sidebarTileList = useMemoized(
      () => getSidebarTileList(context.l10n),
      [context.l10n],
    );

    useEffect(() {
      if (controller.selectedIndex != selectedIndex && selectedIndex != null) {
        controller.selectIndex(selectedIndex!);
      }
      return null;
    }, [selectedIndex]);

    useEffect(() {
      void listener() {
        onSelectedIndexChanged(controller.selectedIndex);
      }

      controller.addListener(listener);
      return () {
        controller.removeListener(listener);
      };
    }, [controller]);

    useEffect(() {
      if (!context.mounted) return;
      if (mediaQuery.lgAndUp && !controller.extended) {
        controller.setExtended(true);
      } else if (mediaQuery.mdAndDown && controller.extended) {
        controller.setExtended(false);
      }
      return null;
    }, [mediaQuery, controller]);

    if (layoutMode == LayoutMode.compact ||
        (mediaQuery.smAndDown && layoutMode == LayoutMode.adaptive)) {
      return Scaffold(body: child);
    }

    return Row(
      children: [
        SafeArea(
          child: SidebarX(
            controller: controller,
            items: sidebarTileList.mapIndexed(
              (index, e) {
                return SidebarXItem(
                  iconWidget: Badge(
                    backgroundColor: theme.colorScheme.primary,
                    isLabelVisible: e.title == "Library" && downloadCount > 0,
                    label: Text(
                      downloadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    child: Icon(
                      e.icon,
                      color: selectedIndex == index
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  label: e.title,
                );
              },
            ).toList(),
            headerBuilder: (_, __) => const SidebarHeader(),
            footerBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: SidebarFooter(),
            ),
            showToggleButton: false,
            theme: SidebarXTheme(
              width: 50,
              margin: EdgeInsets.only(bottom: 10, top: kIsMacOS ? 35 : 5),
              selectedItemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
            ),
            extendedTheme: SidebarXTheme(
              width: 250,
              margin: EdgeInsets.only(
                bottom: 10,
                left: 0,
                top: kIsMacOS ? 0 : 5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: bgColor?.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              selectedItemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
              selectedTextStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              itemTextPadding: const EdgeInsets.only(left: 10),
              selectedItemTextPadding: const EdgeInsets.only(left: 10),
              hoverTextStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        Expanded(child: child)
      ],
    );
  }
}

class SidebarHeader extends HookWidget {
  const SidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    if (mediaQuery.mdAndDown) {
      return Container(
        height: 40,
        width: 40,
        margin: const EdgeInsets.only(bottom: 5),
        child: Sidebar.brandLogo(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (kIsMacOS) const SizedBox(height: 25),
          Row(
            children: [
              Sidebar.brandLogo(),
              const SizedBox(width: 10),
              Text(
                "spotifyre",
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SidebarFooter extends HookConsumerWidget {
  const SidebarFooter({
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final me = ref.watch(meProvider);
    final data = me.asData?.value;

    final avatarImg = (data?.images).asUrlString(
      index: (data?.images?.length ?? 1) - 1,
      placeholder: ImagePlaceholder.artist,
    );

    final auth = ref.watch(authenticationProvider);

    if (mediaQuery.mdAndDown) {
      return IconButton(
        icon: const Icon(spotifyreIcons.settings),
        onPressed: () => Sidebar.goToSettings(context),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 12),
      width: 250,
      child: Column(
        children: [
          const ConnectDeviceButton.sidebar(),
          const Gap(10),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (auth != null && data == null)
                const CircularProgressIndicator()
              else if (data != null)
                Flexible(
                  child: InkWell(
                    onTap: () {
                      ServiceUtils.push(context, "/profile");
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              UniversalImage.imageProvider(avatarImg),
                          onBackgroundImageError: (exception, stackTrace) =>
                              Assets.userPlaceholder.image(
                            height: 16,
                            width: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            data.displayName ?? context.l10n.guest,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(spotifyreIcons.settings),
                onPressed: () {
                  Sidebar.goToSettings(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
