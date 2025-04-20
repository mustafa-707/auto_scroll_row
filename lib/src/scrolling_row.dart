import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';

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

  /// Controls whether the animation should reverse at the end or reset to the beginning.
  /// If true, the animation will reverse direction at the ends instead of jumping back to the start.
  /// Defaults to `true` for ping-pong animation style.
  final bool reverseAtEnds;

  /// Duration to pause scrolling after user interaction before auto-resuming.
  /// Defaults to 3 seconds.
  final Duration pauseDuration;

  /// Constructor for providing a list of widgets directly.
  const AutoScrollRow({
    this.children,
    this.reverse = false,
    this.scrollDuration = const Duration(minutes: 30),
    this.enableUserScroll = true,
    this.reverseAtEnds = true,
    this.pauseDuration = const Duration(seconds: 3),
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
    this.reverseAtEnds = true,
    this.pauseDuration = const Duration(seconds: 3),
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
  bool isForward = true; // Track current animation direction
  Timer? _pauseTimer; // Timer to track pause duration

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Configure the animation controller
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
  void _startScrolling() {
    if (widget.reverseAtEnds) {
      // Use forward-backward animation for ping-pong effect
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
          isForward = false;
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
          isForward = true;
        }
      });
      _controller.forward();
    } else {
      // Use repeat for looping from start
      _controller.repeat();
    }

    _controller.addListener(() {
      if (_scrollController.hasClients && !isDragging) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        double scrollValue;

        if (widget.reverseAtEnds) {
          // Calculate proper scroll position for ping-pong effect
          scrollValue = maxScroll * _controller.value;
        } else {
          // Original looping behavior
          scrollValue = maxScroll * _controller.value;
        }

        // Adjust scroll based on reverse flag (right-to-left vs left-to-right)
        final adjustedScrollValue =
            widget.reverse ? maxScroll - scrollValue : scrollValue;

        // Apply the calculated scroll position
        _scrollController.jumpTo(adjustedScrollValue);
      }
    });
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
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
      // Calculate the current animation position
      double currentScrollPosition = _scrollController.position.pixels;
      double maxScroll = _scrollController.position.maxScrollExtent;

      // Calculate the position within the animation based on the current scroll
      double animationValue = currentScrollPosition / maxScroll;
      if (maxScroll <= 0) animationValue = 0; // Avoid division by zero

      // Adjust the animation value if the reverse flag is set
      if (widget.reverse) {
        animationValue = 1 - animationValue;
      }

      _controller.value = animationValue;

      // Cancel any existing pause timer
      _pauseTimer?.cancel();

      // Set a timer to resume animation after pauseDuration
      _pauseTimer = Timer(widget.pauseDuration, () {
        if (mounted) {
          // Resume animation in the correct direction
          if (widget.reverseAtEnds) {
            if (isForward) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          } else {
            // Original looping behavior
            _controller.repeat();
          }

          // Clear dragging state
          isDragging = false;
        }
      });
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
