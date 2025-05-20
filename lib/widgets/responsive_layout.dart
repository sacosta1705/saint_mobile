import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;
  final EdgeInsets padding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.maxHeight = 1200,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double effectivePaddingW = constraints.maxWidth < 600 ? 8.0 : 16.0;
        double effectivePaddingH = constraints.maxHeight < 600 ? 8.0 : 16.0;

        return Center(
          child: Container(
            constraints:
                BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
            padding: padding.copyWith(
              left: effectivePaddingW,
              right: effectivePaddingW,
              top: effectivePaddingH,
              bottom: effectivePaddingH,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
