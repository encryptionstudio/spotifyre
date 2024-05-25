import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:spotifyre/hooks/utils/use_brightness_value.dart';

class ThemedButtonsTabBar extends HookWidget implements PreferredSizeWidget {
  final List<Widget> tabs;
  const ThemedButtonsTabBar({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = useBrightnessValue(
      theme.colorScheme.primaryContainer,
      Color.lerp(theme.colorScheme.primary, Colors.black, 0.7)!,
    );

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 8,
      ),
      child: ButtonsTabBar(
        radius: 100,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        borderWidth: 0,
        unselectedDecoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.circular(15),
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
        tabs: tabs,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50);
}
