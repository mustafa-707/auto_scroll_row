import 'package:flutter/material.dart';

class AutoScrollRow extends StatefulWidget {
  /// The list of widgets to be displayed in the scrolling row.
  final List<Widget> children;

  /// Determines if the scroll direction should be reversed (right to left).
  /// Defaults to `false`, meaning the scroll direction is left to right.
  final bool reverse;

  /// The total duration for one complete scroll cycle.
  /// Defaults to 30 minutes. You can set a custom duration to control the speed of the scrolling.
  final Duration scrollDuration;

  /// Allows enabling or disabling user interaction with the scroll.
  /// If set to `true` (default), the user can interact and stop the automatic scroll by dragging.
  final bool enableUserScroll;

  const AutoScrollRow({
    required this.children,
    this.reverse = false,
    this.scrollDuration = const Duration(minutes: 30),
    this.enableUserScroll = true,
    Key? key,
  }) : super(key: key);

  @override
  State<AutoScrollRow> createState() => _AutoScrollRowState();
}

class _AutoScrollRowState extends State<AutoScrollRow> with SingleTickerProviderStateMixin {
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
        final adjustedScrollValue = widget.reverse ? maxScroll - scrollValue : scrollValue;

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

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (widget.enableUserScroll && notification is UserScrollNotification) {
          // If the user starts dragging, stop the auto-scrolling
          if (_scrollController.position.isScrollingNotifier.value) {
            if (!isDragging) {
              _controller.stop();
              isDragging = true;
            }
          } else {
            // If the user stops dragging, resume the auto-scrolling from the current position
            if (isDragging) {
              double currentScrollPosition = _scrollController.position.pixels;
              double maxScroll = _scrollController.position.maxScrollExtent;

              // Calculate the position within the animation based on the current scroll
              double animationValue = currentScrollPosition / maxScroll;

              // Adjust the animation value if the reverse flag is set
              _controller.value = widget.reverse ? 1 - animationValue : animationValue;

              _controller.repeat();
              isDragging = false;
            }
          }
        }
        return false;
      },
      // The row of widgets is placed inside a horizontally scrolling container
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.children,
        ),
      ),
    );
  }
}
