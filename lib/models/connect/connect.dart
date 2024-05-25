library connect;

import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spotify/spotify.dart';
import 'package:spotifyre/extensions/track.dart';
import 'package:spotifyre/provider/proxy_playlist/proxy_playlist.dart';
import 'package:spotifyre/services/audio_player/loop_mode.dart';

part 'connect.freezed.dart';
part 'connect.g.dart';

part 'ws_event.dart';
part 'load.dart';
