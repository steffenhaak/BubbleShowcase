import 'package:bubble_showcase/src/shape.dart';
import 'package:bubble_showcase/src/showcase.dart';
import 'package:bubble_showcase/src/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A function that allows to calculate a position according to a provided size.
typedef Position PositionCalculator(Size size);

/// A simple bubble slide that allows to highlight a specific screen zone.
abstract class BubbleSlide {
  /// The slide shape.
  final Shape shape;

  /// The box shadow.
  final BoxShadow boxShadow;

  /// The slide child.
  final BubbleSlideChild child;

  /// Creates a new bubble slide instance.
  const BubbleSlide({
    this.shape = const Rectangle(),
    this.boxShadow = const BoxShadow(
      color: Colors.black54,
      blurRadius: 0,
      spreadRadius: 0,
    ),
    this.child,
  });

  /// Builds the whole slide widget.
  Widget build(BuildContext context, BubbleShowcase bubbleShowcase,
      int currentSlideIndex, void Function(int) goToSlide) {
    Position highlightPosition =
        getHighlightPosition(context, bubbleShowcase, currentSlideIndex);
    if (highlightPosition == null) return const SizedBox();
    List<Widget> children = [
      Positioned.fill(
        child: CustomPaint(
          painter: OverlayPainter(this, highlightPosition),
        ),
      ),
    ];

    int slidesCount = bubbleShowcase.bubbleSlides.length;
    Color writeColor =
        Util.isColorDark(boxShadow.color) ? Colors.white : Colors.black;
    if (bubbleShowcase.counterText != null) {
      children.add(
        Positioned(
          bottom: MediaQuery.of(context).viewPadding.bottom + 4.0,
          left: 0,
          right: 0,
          child: Text(
            bubbleShowcase.counterText
                .replaceAll(':i', (currentSlideIndex + 1).toString())
                .replaceAll(':n', slidesCount.toString()),
            style:
                Theme.of(context).textTheme.body1.copyWith(color: writeColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (child != null && child.widget != null) {
      children.add(
          child.build(context, highlightPosition, MediaQuery.of(context).size));
    }

    if (bubbleShowcase.showCloseButton) {
      children.add(Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 8.0,
        child: GestureDetector(
          child: Icon(
            Icons.close,
            color: writeColor,
          ),
          onTap: () => goToSlide(slidesCount),
        ),
      ));
    }

    return GestureDetector(
      onTap: () => goToSlide(currentSlideIndex + 1),
      child: Stack(
        children: children,
      ),
    );
  }

  /// Returns the position to highlight.
  Position getHighlightPosition(BuildContext context,
      BubbleShowcase bubbleShowcase, int currentSlideIndex);
}

/// A bubble slide with a position that depends on another widget.
class RelativeBubbleSlide extends BubbleSlide {
  /// The widget key.
  final GlobalKey widgetKey;

  /// Creates a new relative bubble slide instance.
  const RelativeBubbleSlide({
    Shape shape = const Rectangle(),
    BoxShadow boxShadow = const BoxShadow(
      color: Colors.black54,
      blurRadius: 0,
      spreadRadius: 0,
    ),
    BubbleSlideChild child,
    @required this.widgetKey,
  }) : super(
          shape: shape,
          boxShadow: boxShadow,
          child: child,
        );

  @override
  Position getHighlightPosition(BuildContext context,
      BubbleShowcase bubbleShowcase, int currentSlideIndex) {
    final currentContext = widgetKey.currentContext;
    if (currentContext == null) return null;
    RenderObject object = currentContext.findRenderObject();
    RenderBox renderBox = object as RenderBox;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);

    ScrollableState scrollableState = Scrollable.of(widgetKey.currentContext);

    if (viewport != null && scrollableState != null) {
      ScrollPosition position = scrollableState.position;
      double alignment;
      if (position.pixels > viewport.getOffsetToReveal(object, 0.0).offset) {
        // Move down to the top of the viewport
        alignment = 0.0;
      } else if (position.pixels <
          viewport.getOffsetToReveal(object, 1.0).offset) {
        // Move up to the bottom of the viewport
        alignment = 1.0;
      }

      if (alignment != null) {
        position.ensureVisible(
          object,
          alignment: alignment,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        ).then((_) => Overlay.of(context).setState(() {}));
        return null;
      }
    }

    return Position(
      top: offset.dy,
      right: offset.dx + renderBox.size.width,
      bottom: offset.dy + renderBox.size.height,
      left: offset.dx,
    );
  }
}

/// A bubble slide with an absolute position on the screen.
class AbsoluteBubbleSlide extends BubbleSlide {
  /// The function that allows to compute the highlight position according to the parent size.
  final PositionCalculator positionCalculator;

  /// Creates a new absolute bubble slide instance.
  const AbsoluteBubbleSlide({
    Shape shape = const Rectangle(),
    BoxShadow boxShadow = const BoxShadow(
      color: Colors.black54,
      blurRadius: 0,
      spreadRadius: 0,
    ),
    BubbleSlideChild child,
    @required this.positionCalculator,
  }) : super(
          shape: shape,
          boxShadow: boxShadow,
          child: child,
        );

  @override
  Position getHighlightPosition(BuildContext context,
          BubbleShowcase bubbleShowcase, int currentSlideIndex) =>
      positionCalculator(MediaQuery.of(context).size);
}

/// A bubble slide child, holding a widget.
abstract class BubbleSlideChild {
  /// The held widget.
  final Widget widget;

  /// Creates a new bubble slide child instance.
  const BubbleSlideChild({
    this.widget,
  });

  /// Builds the bubble slide child widget.
  Widget build(BuildContext context, Position targetPosition, Size parentSize) {
    Position position = getPosition(context, targetPosition, parentSize);
    return Positioned(
      top: position.top,
      right: position.right,
      bottom: position.bottom,
      left: position.left,
      child: widget,
    );
  }

  /// Returns child position according to the highlight position and parent size.
  Position getPosition(
      BuildContext context, Position highlightPosition, Size parentSize);
}

/// A bubble slide with a position that depends on the highlight zone.
class RelativeBubbleSlideChild extends BubbleSlideChild {
  /// The child direction.
  final AxisDirection direction;
  final double extraWidth;
  final double extraHeight;
  final double extraWidthLeft;
  final double extraWidthRight;
  final double extraHeightTop;
  final double extraHeightBottom;

  /// Creates a new relative bubble slide child instance.
  const RelativeBubbleSlideChild({
    Widget widget,
    this.direction = AxisDirection.down,
    this.extraWidth,
    this.extraHeight,
    this.extraWidthLeft,
    this.extraWidthRight,
    this.extraHeightTop,
    this.extraHeightBottom,
  }) : super(
          widget: widget,
        );

  @override
  Position getPosition(
      BuildContext context, Position highlightPosition, Size parentSize) {
    switch (direction) {
      case AxisDirection.up:
        return Position(
          right:
              parentSize.width - highlightPosition.right - (extraWidthRight ?? extraWidth ?? 0.0),
          bottom: parentSize.height - highlightPosition.top,
          left: highlightPosition.left - (extraWidthLeft ?? extraWidth ?? 0.0),
        );
      case AxisDirection.right:
        return Position(
          top: highlightPosition.top - (extraHeightTop ?? extraHeight ?? 0.0),
          bottom: parentSize.height -
              highlightPosition.bottom -
              (extraHeightBottom ?? extraHeight ?? 0.0),
          left: highlightPosition.right,
        );
      case AxisDirection.left:
        return Position(
          top: highlightPosition.top - (extraHeightTop ?? extraHeight ?? 0.0),
          bottom: parentSize.height -
              highlightPosition.bottom -
              (extraHeightBottom ?? extraHeight ?? 0.0),
          right: parentSize.width - highlightPosition.left,
        );
      default:
        return Position(
          top: highlightPosition.bottom,
          right:
              parentSize.width - highlightPosition.right - (extraWidthRight ?? extraWidth ?? 0.0),
          left: highlightPosition.left - (extraWidthLeft ?? extraWidth ?? 0.0),
        );
    }
  }
}

/// A bubble slide child with an absolute position on the screen.
class AbsoluteBubbleSlideChild extends BubbleSlideChild {
  /// The function that allows to compute the child position according to the parent size.
  final PositionCalculator positionCalculator;

  /// Creates a new absolute bubble slide child instance.
  const AbsoluteBubbleSlideChild({
    Widget widget,
    @required this.positionCalculator,
  }) : super(
          widget: widget,
        );

  @override
  Position getPosition(
          BuildContext context, Position highlightPosition, Size parentSize) =>
      positionCalculator(parentSize);
}
