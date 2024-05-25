import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotifyre/collections/spotifyre_icons.dart';

class VolumeSlider extends HookConsumerWidget {
  final bool fullWidth;

  final double value;
  final ValueChanged<double> onChanged;

  const VolumeSlider({
    super.key,
    this.fullWidth = false,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, ref) {
    var slider = Listener(
      onPointerSignal: (event) async {
        if (event is PointerScrollEvent) {
          if (event.scrollDelta.dy > 0) {
            final newValue = value - .2;
            onChanged(newValue < 0 ? 0 : newValue);
          } else {
            final newValue = value + .2;
            onChanged(newValue > 1 ? 1 : newValue);
          }
        }
      },
      child: Slider(
        min: 0,
        max: 1,
        value: value,
        onChanged: onChanged,
      ),
    );
    return Row(
      mainAxisAlignment:
          !fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(
            value == 0
                ? spotifyreIcons.volumeMute
                : value <= 0.2
                    ? spotifyreIcons.volumeLow
                    : value <= 0.6
                        ? spotifyreIcons.volumeMedium
                        : spotifyreIcons.volumeHigh,
            size: 16,
          ),
          onPressed: () {
            if (value == 0) {
              onChanged(1);
            } else {
              onChanged(0);
            }
          },
        ),
        if (fullWidth) Expanded(child: slider) else slider,
      ],
    );
  }
}
