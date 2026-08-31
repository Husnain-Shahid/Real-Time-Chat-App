import 'package:flutter/material.dart';

/// Standard device breakpoints for responsiveness
class ResponsiveBreakpoints {
  static const double mobileMax = 767.0;
  static const double tabletMin = 768.0;
  static const double desktopMin = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletMin;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletMin;
  }
}

/// A versatile widget that uses [LayoutBuilder] to supply layout conditions.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints, bool isTablet) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= ResponsiveBreakpoints.tabletMin;
        return builder(context, constraints, isTablet);
      },
    );
  }
}

/// Constrains tablet/desktop content to a maximum comfortable width (e.g. for forms/profiles).
class ResponsiveCenteredContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenteredContainer({
    super.key,
    required this.child,
    this.maxWidth = 720.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > maxWidth) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}
