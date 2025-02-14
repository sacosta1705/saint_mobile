import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  // const ResponsiveLayout({
  //   Key? key,
  //   required this.child,
  //   this.maxWidth = 1200,
  //   this.padding = const EdgeInsets.all(16.0),
  // }) : super(key: key);

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double effectivePadding = constraints.maxWidth < 600 ? 8.0 : 16.0;

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: padding.copyWith(
              left: effectivePadding,
              right: effectivePadding,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
