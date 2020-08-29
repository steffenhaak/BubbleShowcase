library bubble_showcase;

import 'package:bubble_showcase/bubble_showcase.dart';
import 'package:bubble_showcase/src/controller.dart';
import 'package:bubble_showcase/src/slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The BubbleShowcase main widget.
class BubbleShowcase extends StatefulWidget {

  /// All slides.
  final List<BubbleSlide> bubbleSlides;

  /// The child widget (displayed below the showcase).
  final Widget child;

  /// The counter text (:i is the current slide, :n is the slides count). You can pass null to disable this.
  final String counterText;

  /// Whether to show a close button.
  final bool showCloseButton;

  final BubbleShowcaseController controller;

  /// Creates a new bubble showcase instance.
  BubbleShowcase({
    @required this.bubbleSlides,
    this.child,
    this.counterText = ':i/:n',
    this.showCloseButton = true,
    @required this.controller,
  })  : assert(bubbleSlides.isNotEmpty),
        assert(controller != null);

  @override
  State<StatefulWidget> createState() => _BubbleShowcaseState();

}

/// The BubbleShowcase state.
class _BubbleShowcaseState extends State<BubbleShowcase>
    with WidgetsBindingObserver {
  /// The current slide index.
  int _currentSlideIndex = -1;

  bool get open => _open;
  bool _open;

  /// The current slide entry.
  OverlayEntry _currentSlideEntry;

  @override
  void initState() {
    if (_currentSlideEntry != null) {
      _currentSlideEntry.remove();
    }
    WidgetsBinding.instance.addObserver(this);
    widget.controller?.addListener(_controllerValueChanged);

    super.initState();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _showOverlay() {
    _currentSlideIndex = 0;
    _currentSlideEntry = _createCurrentSlideEntry();
    Overlay.of(context).insert(_currentSlideEntry);
  }

  @override
  void didUpdateWidget(BubbleShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      debugPrint('didUpdateWidget !=');
      oldWidget.controller?.removeListener(_controllerValueChanged);
      widget.controller?.addListener(_controllerValueChanged);
    }
  }

  void _controllerValueChanged() {
    if (widget.controller.value) {
      _showOverlay();
    }
  }

  @override
  void dispose() {
    _currentSlideEntry?.remove();
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_controllerValueChanged);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_currentSlideEntry == null) {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_currentSlideEntry != null) {
        _currentSlideEntry.remove();
        Overlay.of(context).insert(_currentSlideEntry);
      }
    });
  }

  /// Returns whether the showcasing is finished.
  bool get _isFinished =>
      _currentSlideIndex == -1 ||
      _currentSlideIndex == widget.bubbleSlides.length;

  /// Allows to go to the next entry (or to close the showcase if needed).
  void _goToNextEntryOrClose(int position) {
    _currentSlideIndex = position;
    _currentSlideEntry.remove();

    if (_isFinished) {
      _currentSlideEntry = null;
      widget.controller.value = false;
    } else {
      _currentSlideEntry = _createCurrentSlideEntry();
      Overlay.of(context).insert(_currentSlideEntry);
    }
  }

  /// Creates the current slide entry.
  OverlayEntry _createCurrentSlideEntry() => OverlayEntry(
        builder: (context) => widget.bubbleSlides[_currentSlideIndex].build(
          context,
          widget,
          _currentSlideIndex,
          (position) {
            setState(() => _goToNextEntryOrClose(position));
          },
        ),
      );
}
