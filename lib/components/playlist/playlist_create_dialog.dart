import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_validator/form_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spotify/spotify.dart';

import 'package:spotifyre/collections/spotifyre_icons.dart';
import 'package:spotifyre/components/shared/image/universal_image.dart';
import 'package:spotifyre/extensions/constrains.dart';
import 'package:spotifyre/extensions/context.dart';
import 'package:spotifyre/extensions/image.dart';
import 'package:spotifyre/provider/spotify/spotify.dart';
import 'package:spotifyre/provider/spotify_provider.dart';

class PlaylistCreateDialog extends HookConsumerWidget {
  /// Track ids to add to the playlist
  final List<String> trackIds;
  final String? playlistId;
  PlaylistCreateDialog({
    super.key,
    this.trackIds = const [],
    this.playlistId,
  });

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, ref) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: HookBuilder(builder: (context) {
          final userPlaylists = ref.watch(favoritePlaylistsProvider);
          final playlist = ref.watch(playlistProvider(playlistId ?? ""));
          final playlistNotifier =
              ref.watch(playlistProvider(playlistId ?? "").notifier);

          final updatingPlaylist = useMemoized(
            () => userPlaylists.asData?.value.items
                .firstWhereOrNull((playlist) => playlist.id == playlistId),
            [
              userPlaylists.asData?.value.items,
              playlistId,
            ],
          );

          final playlistName = useTextEditingController(
            text: updatingPlaylist?.name,
          );
          final description = useTextEditingController(
            text: updatingPlaylist?.description,
          );
          final public = useState(
            updatingPlaylist?.public ?? false,
          );
          final collaborative = useState(
            updatingPlaylist?.collaborative ?? false,
          );
          final image = useState<XFile?>(null);

          final isUpdatingPlaylist = playlistId != null;

          final l10n = context.l10n;
          final theme = Theme.of(context);
          final scaffold = ScaffoldMessenger.of(context);

          final onError = useCallback((error) {
            if (error is SpotifyError || error is SpotifyException) {
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.error(error.message ?? "Epic failure!"),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onError,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          }, [scaffold, l10n, theme]);

          Future<void> onCreate() async {
            if (!formKey.currentState!.validate()) return;

            final PlaylistInput payload = (
              playlistName: playlistName.text,
              collaborative: collaborative.value,
              public: public.value,
              description: description.text,
              base64Image: image.value?.path != null
                  ? await image.value!
                      .readAsBytes()
                      .then((bytes) => base64Encode(bytes))
                  : null,
            );

            if (isUpdatingPlaylist) {
              await playlistNotifier.modify(payload, onError);
            } else {
              await playlistNotifier.create(payload, onError);
            }

            if (context.mounted &&
                !ref.read(playlistProvider(playlistId ?? "")).hasError) {
              context.pop();
            }
          }

          return AlertDialog(
            title: Text(
              isUpdatingPlaylist
                  ? context.l10n.update_playlist
                  : context.l10n.create_a_playlist,
            ),
            actions: [
              OutlinedButton(
                child: Text(context.l10n.cancel),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FilledButton(
                onPressed: playlist.isLoading ? null : onCreate,
                child: Text(
                  isUpdatingPlaylist
                      ? context.l10n.update
                      : context.l10n.create,
                ),
              ),
            ],
            insetPadding: const EdgeInsets.all(8),
            content: Container(
              width: MediaQuery.of(context).size.width,
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    FormField<XFile?>(
                        initialValue: image.value,
                        onSaved: (newValue) {
                          image.value = newValue;
                        },
                        validator: (value) {
                          if (value == null) return null;
                          final file = File(value.path);

                          if (file.lengthSync() > 256000) {
                            return "Image size should be less than 256kb";
                          }
                          return null;
                        },
                        builder: (field) {
                          return Column(
                            children: [
                              UniversalImage(
                                path: field.value?.path ??
                                    (updatingPlaylist?.images).asUrlString(
                                      placeholder: ImagePlaceholder.collection,
                                    ),
                                height: 200,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    icon: const Icon(spotifyreIcons.edit),
                                    label: Text(
                                      field.value?.path != null ||
                                              updatingPlaylist?.images != null
                                          ? context.l10n.change_cover
                                          : context.l10n.add_cover,
                                    ),
                                    onPressed: () async {
                                      final imageFile = await ImagePicker()
                                          .pickImage(
                                              source: ImageSource.gallery);

                                      if (imageFile != null) {
                                        field.didChange(imageFile);
                                        field.validate();
                                        field.save();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton.filled(
                                    icon: const Icon(spotifyreIcons.trash),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.errorContainer,
                                      foregroundColor: theme.colorScheme.error,
                                    ),
                                    onPressed: field.value == null
                                        ? null
                                        : () {
                                            field.didChange(null);
                                            field.validate();
                                            field.save();
                                          },
                                  ),
                                ],
                              ),
                              if (field.hasError)
                                Text(
                                  field.errorText ?? "",
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                )
                            ],
                          );
                        }),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: playlistName,
                      decoration: InputDecoration(
                        hintText: context.l10n.name_of_playlist,
                        labelText: context.l10n.name_of_playlist,
                      ),
                      validator: ValidationBuilder().required().build(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: description,
                      decoration: InputDecoration(
                        hintText: context.l10n.description,
                      ),
                      keyboardType: TextInputType.multiline,
                      validator: ValidationBuilder().required().build(),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text(context.l10n.public),
                      value: public.value,
                      onChanged: (val) => public.value = val ?? false,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text(context.l10n.collaborative),
                      value: collaborative.value,
                      onChanged: (val) => collaborative.value = val ?? false,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PlaylistCreateDialogButton extends HookConsumerWidget {
  const PlaylistCreateDialogButton({super.key});

  showPlaylistDialog(BuildContext context, SpotifyApi spotify) {
    showDialog(
      context: context,
      builder: (context) => PlaylistCreateDialog(),
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final mediaQuery = MediaQuery.of(context);
    final spotify = ref.watch(spotifyProvider);

    if (mediaQuery.smAndDown) {
      return ElevatedButton(
        style: FilledButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        child: const Icon(spotifyreIcons.addFilled),
        onPressed: () => showPlaylistDialog(context, spotify),
      );
    }

    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      icon: const Icon(spotifyreIcons.addFilled),
      label: Text(context.l10n.create_playlist),
      onPressed: () => showPlaylistDialog(context, spotify),
    );
  }
}
