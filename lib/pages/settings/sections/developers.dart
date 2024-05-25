import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/settings/section_card_with_heading.dart';
import 'package:spotifyre/extensions/context.dart';

class SettingsDevelopersSection extends HookWidget {
  const SettingsDevelopersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCardWithHeading(
      heading: context.l10n.developers,
      children: [
        ListTile(
          leading: const Icon(spotifyreIcons.logs),
          title: Text(context.l10n.logs),
          trailing: const Icon(spotifyreIcons.angleRight),
          onTap: () {
            GoRouter.of(context).push("/settings/logs");
          },
        )
      ],
    );
  }
}
