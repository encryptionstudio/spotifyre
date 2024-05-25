import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class spotifyrePage<T> extends MaterialPage<T> {
  const spotifyrePage({required super.child});
}

class spotifyreSlidePage extends CustomTransitionPage {
  spotifyreSlidePage({
    required super.child,
    super.key,
  }) : super(
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        );
}
