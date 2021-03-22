import 'package:bubble_showcase/src/slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Contains some useful methods.
class Utils {
  /// Returns whether a specified color is dark.
  static bool isColorDark(Color color) => color.computeLuminance() <= 0.5;
}

/// Represents a position on the screen.
class Position {
  /// The top coordinate.
  final double? top;

  /// The right coordinate.
  final double? right;

  /// The bottom coordinate.
  final double? bottom;

  /// The left coordinate.
  final double? left;

  /// Creates a new position instance.
  const Position({
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  @override
  String toString() =>
      'Position(top: $top, right: $right, bottom: $bottom, left: $left)';

  @override
  bool operator ==(Object other) =>
      other is Position &&
      top == other.top &&
      right == other.right &&
      bottom == other.bottom &&
      left == other.left;

  @override
  int get hashCode {
    int result = 17;
    result = result * 31 + (top?.truncate() ?? 0);
    result = result * 31 + (right?.truncate() ?? 0);
    result = result * 31 + (bottom?.truncate() ?? 0);
    result = result * 31 + (left?.truncate() ?? 0);
    return result;
  }
}

/// A simple painter that allows to highlight a specific zone on the screen by darkening the whole screen (apart the specified zone).
class OverlayPainter extends CustomPainter {
  /// The bubble slide.
  final BubbleSlide _slide;

  /// The position to highlight.
  final Position _position;

  /// Creates a new overlay painter instance.
  const OverlayPainter(this._slide, this._position);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size,
        Paint()); // Thanks to https://stackoverflow.com/a/51548959.
    canvas.drawColor(_slide.boxShadow.color, BlendMode.dstATop);
    final paint = _slide.boxShadow.toPaint();
    if (!kIsWeb) paint.blendMode = BlendMode.clear;
    _slide.shape.drawOnCanvas(
      canvas,
      Rect.fromLTRB(
        _position.left ?? 0,
        _position.top ?? 0,
        _position.right ?? size.width,
        _position.bottom ?? size.height,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(OverlayPainter oldOverlay) =>
      oldOverlay._position != _position;
}
