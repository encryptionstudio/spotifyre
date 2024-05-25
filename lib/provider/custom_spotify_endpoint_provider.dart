import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/provider/spotify_provider.dart';
import 'package:spotifyre/services/custom_spotify_endpoints/spotify_endpoints.dart';

final customSpotifyEndpointProvider = Provider<CustomSpotifyEndpoints>((ref) {
  ref.watch(spotifyProvider);
  final auth = ref.watch(authenticationProvider);
  return CustomSpotifyEndpoints(auth?.accessToken ?? "");
});
