import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class AutoScrollRow extends StatefulWidget {
  /// The list of widgets to be displayed in the scrolling row.
  final List<Widget>? children;

  /// A builder function that returns widgets on demand.
  final IndexedWidgetBuilder? itemBuilder;

  /// The total number of items when using a builder.
  final int? itemCount;

  /// Determines if the scroll direction should be reversed (right to left).
  /// Defaults to `false`, meaning the scroll direction is left to right.
  final bool reverse;

  /// The total duration for one complete scroll cycle.
  /// Defaults to 30 minutes. You can set a custom duration to control the speed of the scrolling.
  final Duration scrollDuration;

  /// Allows enabling or disabling user interaction with the scroll.
  /// If set to `true` (default), the user can interact and stop the automatic scroll by dragging.
  final bool enableUserScroll;

  /// Constructor for providing a list of widgets directly.
  const AutoScrollRow({
    this.children,
    this.reverse = false,
    this.scrollDuration = const Duration(minutes: 30),
    this.enableUserScroll = true,
    Key? key,
  })  : itemBuilder = null,
        itemCount = null,
        assert(children != null,
            'Children must not be null when using this constructor'),
        super(key: key);

  /// Constructor for using a builder pattern to efficiently render only visible items.
  const AutoScrollRow.builder({
    required this.itemBuilder,
    required this.itemCount,
    this.reverse = false,
    this.scrollDuration = const Duration(minutes: 30),
    this.enableUserScroll = true,
    Key? key,
  })  : children = null,
        assert(itemBuilder != null && itemCount != null,
            'ItemBuilder and itemCount must not be null when using builder constructor'),
        super(key: key);

  @override
  State<AutoScrollRow> createState() => _AutoScrollRowState();
}

class _AutoScrollRowState extends State<AutoScrollRow>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _controller;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Create an animation controller with the duration provided by the user
    _controller = AnimationController(
      vsync: this,
      duration: widget.scrollDuration,
    );

    // After the first frame is rendered, start the auto-scrolling animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  /// Starts the automatic scrolling of the row.
  /// The animation controller drives the scroll, and it repeats indefinitely.
  void _startScrolling() {
    _controller.repeat();
    _controller.addListener(() {
      if (_scrollController.hasClients && !isDragging) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final scrollValue = maxScroll * _controller.value;

        // Adjust scroll based on reverse flag: scroll right-to-left if reverse is true
        final adjustedScrollValue =
            widget.reverse ? maxScroll - scrollValue : scrollValue;

        // Jump to the calculated scroll position or reset to 0 if the end is reached
        if (adjustedScrollValue < maxScroll) {
          _scrollController.jumpTo(adjustedScrollValue);
        } else {
          _scrollController.jumpTo(0);
        }
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the animation and scroll controllers to avoid memory leaks
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Handle user scroll interaction start
  void _handleDragStart() {
    if (widget.enableUserScroll && !isDragging) {
      _controller.stop();
      isDragging = true;
    }
  }

  // Handle user scroll interaction end
  void _handleDragEnd() {
    if (widget.enableUserScroll && isDragging) {
      double currentScrollPosition = _scrollController.position.pixels;
      double maxScroll = _scrollController.position.maxScrollExtent;

      // Calculate the position within the animation based on the current scroll
      double animationValue = currentScrollPosition / maxScroll;
      if (maxScroll <= 0) animationValue = 0; // Avoid division by zero

      // Adjust the animation value if the reverse flag is set
      _controller.value = widget.reverse ? 1 - animationValue : animationValue;

      _controller.repeat();
      isDragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Explicitly handle drag gestures for reliable interaction
      onHorizontalDragStart: (_) => _handleDragStart(),
      onHorizontalDragEnd: (_) => _handleDragEnd(),

      // Use Listener to catch all pointer events
      child: Listener(
        onPointerDown: (_) => _handleDragStart(),
        onPointerUp: (_) => _handleDragEnd(),
        onPointerCancel: (_) => _handleDragEnd(),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: widget.enableUserScroll
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          dragStartBehavior: DragStartBehavior.down,
          child: _buildContent(),
        ),
      ),
    );
  }

  /// Builds either a simple Row with children or creates widgets using the builder pattern
  Widget _buildContent() {
    if (widget.children != null) {
      // Original implementation with direct children
      return Row(children: widget.children!);
    } else {
      // Create a row dynamically using itemBuilder
      return Row(
        children: List.generate(
          widget.itemCount!,
          (index) => widget.itemBuilder!(context, index),
        ),
      );
    }
  }
}
