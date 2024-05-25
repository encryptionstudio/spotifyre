import 'package:flutter/material.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SideBarTiles {
  final IconData icon;
  final String title;
  final String id;
  SideBarTiles({required this.icon, required this.title, required this.id});
}

List<SideBarTiles> getSidebarTileList(AppLocalizations l10n) => [
      SideBarTiles(id: "browse", icon: spotifyreIcons.home, title: l10n.browse),
      SideBarTiles(
          id: "search", icon: spotifyreIcons.search, title: l10n.search),
      SideBarTiles(
          id: "library", icon: spotifyreIcons.library, title: l10n.library),
      SideBarTiles(
          id: "lyrics", icon: spotifyreIcons.music, title: l10n.lyrics),
    ];

List<SideBarTiles> getNavbarTileList(AppLocalizations l10n) => [
      SideBarTiles(id: "browse", icon: spotifyreIcons.home, title: l10n.browse),
      SideBarTiles(
          id: "search", icon: spotifyreIcons.search, title: l10n.search),
      SideBarTiles(
        id: "library",
        icon: spotifyreIcons.library,
        title: l10n.library,
      ),
      SideBarTiles(
        id: "settings",
        icon: spotifyreIcons.settings,
        title: l10n.settings,
      )
    ];
