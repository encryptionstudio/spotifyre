import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotifyre/extensions/context.dart';

import 'package:spotifyre/provider/authentication_provider.dart';
import 'package:spotifyre/utils/service_utils.dart';

class AnonymousFallback extends ConsumerWidget {
  final Widget? child;
  const AnonymousFallback({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context, ref) {
    final isLoggedIn = ref.watch(authenticationProvider) != null;

    if (isLoggedIn && child != null) return child!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(context.l10n.not_logged_in),
          const SizedBox(height: 10),
          FilledButton(
            child: Text(context.l10n.login_with_spotify),
            onPressed: () => ServiceUtils.push(context, "/settings"),
          )
        ],
      ),
    );
  }
}
