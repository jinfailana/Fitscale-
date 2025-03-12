import 'package:flutter/material.dart';

enum TransitionType {
  rightToLeft,
  leftToRight,
  bottomToTop,
  topToBottom,
  fade,
  scale,
}

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;
  final TransitionType transitionType;
  final Duration duration;
  final Curve curve;

  CustomPageRoute({
    required this.child,
    this.transitionType = TransitionType.rightToLeft,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            switch (transitionType) {
              case TransitionType.rightToLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case TransitionType.leftToRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case TransitionType.bottomToTop:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case TransitionType.topToBottom:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -1.0),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case TransitionType.fade:
                return FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(curvedAnimation),
                  child: child,
                );
              case TransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.8,
                    end: 1.0,
                  ).animate(curvedAnimation),
                  child: FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.5,
                      end: 1.0,
                    ).animate(curvedAnimation),
                    child: child,
                  ),
                );
            }
          },
        );
} 