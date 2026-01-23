import 'package:flutter/material.dart';

/// A toggle button for starting/stopping Radio mode (shuffle all tracks)
///
/// Custom animated button with controlled state management.
/// Tap to start music (button lights up with pink glow), tap again to stop (button dims).
class RadioButton extends StatelessWidget {
  /// Callback when the button is toggled
  final VoidCallback onToggle;

  /// Whether music is currently playing (determines toggle state)
  final bool isPlaying;

  /// Whether the button is in a loading state
  final bool isLoading;

  const RadioButton({
    super.key,
    required this.onToggle,
    this.isPlaying = false,
    this.isLoading = false,
  });

  // Design constants
  static const double _buttonSize = 80.0;
  static const double _iconSize = 40.0;
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Curve _animationCurve = Curves.easeInOut;

  // Colors
  static const Color _onColor = Color(0xFFFF0083); // Pink/magenta
  static const Color _offBackgroundColor = Color(0xFF2A2A2A); // Dark gray
  static const Color _onBackgroundColor = Color(0xFF3A1A2A); // Dark with pink tint
  static const Color _offIconColor = Color(0xFF666666); // Gray

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isPlaying
          ? 'Radio is on - Tap to stop music'
          : 'Radio is off - Tap to shuffle and play all music',
      child: GestureDetector(
        onTap: isLoading ? null : onToggle,
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: _animationCurve,
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPlaying ? _onBackgroundColor : _offBackgroundColor,
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: _onColor.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: isLoading ? _buildLoadingIndicator(context) : _buildIcon(),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: isPlaying ? 1.0 : 1.05,
        end: isPlaying ? 1.05 : 1.0,
      ),
      duration: _animationDuration,
      curve: _animationCurve,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.power_settings_new,
            size: _iconSize,
            color: isPlaying ? _onColor : _offIconColor,
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
