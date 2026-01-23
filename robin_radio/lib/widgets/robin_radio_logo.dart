import 'package:flutter/material.dart';

/// Robin Radio branding logo widget.
///
/// Displays either the full logo with text or simplified icon only.
class RobinRadioLogo extends StatelessWidget {
  /// The height of the logo. Width is automatically calculated to maintain
  /// aspect ratio.
  final double height;

  /// When true, displays the full logo with "Robin Radio" text.
  /// When false (default), displays only the simplified icon.
  final bool showText;

  const RobinRadioLogo({
    super.key,
    this.height = 40,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      showText
          ? 'assets/branding/logo_full.png'
          : 'assets/branding/logo_icon.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Robin Radio logo',
    );
  }
}
