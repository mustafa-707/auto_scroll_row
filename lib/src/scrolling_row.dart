import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';

class AutoScrollRow extends StatefulWidget {
  /// The list of widgets to be displayed in the scrolling row.
  final List<Widget>? children;

  /// A builder function that returns widgets on demand.
  final IndexedWidgetBuilder? itemBuilder;

  /// A builder function that returns a separator widget.
  final IndexedWidgetBuilder? separatorBuilder;

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
        separatorBuilder = null,
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
        separatorBuilder = null,
        assert(itemBuilder != null && itemCount != null,
            'ItemBuilder and itemCount must not be null when using builder constructor'),
        super(key: key);

  /// Constructor for using a builder pattern with separators.
  const AutoScrollRow.separated({
    required this.itemBuilder,
    required this.itemCount,
    required this.separatorBuilder,
    this.reverse = false,
    this.scrollDuration = const Duration(minutes: 30),
    this.enableUserScroll = true,
    this.reverseAtEnds = true,
    this.pauseDuration = const Duration(seconds: 3),
    Key? key,
  })  : children = null,
        assert(
            itemBuilder != null &&
                itemCount != null &&
                separatorBuilder != null,
            'ItemBuilder, itemCount, and separatorBuilder must not be null when using separated constructor'),
        super(key: key);

  @override
  State<AutoScrollRow> createState() => _AutoScrollRowState();
}

class _AutoScrollRowState extends State<AutoScrollRow> {
  late final ScrollController _scrollController;
  bool isDragging = false;
  Timer? _pauseTimer; // Timer to track pause duration

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // After the first frame is rendered, start the auto-scrolling animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  /// Starts the automatic scrolling of the row.
  Future<void> _startScrolling() async {
    // Safety check: ensure scroll controller has clients before starting
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    // Initial setup: If reversing, we might want to start at the end
    try {
      if (widget.reverse && _scrollController.offset == 0) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _scrollController.jumpTo(maxScroll);
        }
      }
    } catch (_) {
      // Ignore errors during initial setup
    }

    // Continuous scrolling loop
    while (mounted && !isDragging) {
      if (!_scrollController.hasClients) return;

      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.offset;

      if (maxScroll <= 0) {
        // No scrollable content, wait and retry
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      double target = 0;
      bool shouldJump = false;

      // Determine target based on configuration and current position
      if (widget.reverse) {
        // RTL Mode: Natural direction is Max -> 0
        if (currentScroll <= 0.5) {
          // At start (0), need to reset to Max
          if (widget.reverseAtEnds) {
            target = maxScroll; // Ping-pong: animate back to Max
          } else {
            shouldJump = true; // Loop: jump to Max then animate to 0
            target = 0;
          }
        } else {
          target = 0; // Animate towards 0
        }
      } else {
        // LTR Mode: Natural direction is 0 -> Max
        if (currentScroll >= maxScroll - 0.5) {
          // At end (Max), need to reset to 0
          if (widget.reverseAtEnds) {
            target = 0; // Ping-pong: animate back to 0
          } else {
            shouldJump = true; // Loop: jump to 0 then animate to Max
            target = maxScroll;
          }
        } else {
          target = maxScroll; // Animate towards Max
        }
      }

      // Execute the scroll action
      if (shouldJump) {
        try {
          _scrollController.jumpTo(target == 0 ? maxScroll : 0);
          // After jump, current position changed, so we proceed to animate to target
        } catch (_) {}
      }

      // Calculate duration proportional to distance to maintain constant speed
      // Since we jumped (if needed), re-read current position
      final double newCurrent = _scrollController.offset;
      final double distance = (target - newCurrent).abs();

      if (distance > 1.0) {
        final Duration duration = maxScroll > 0
            ? widget.scrollDuration * (distance / maxScroll)
            : Duration.zero;

        try {
          // Use linear curve for smooth constant speed
          await _scrollController.animateTo(
            target,
            duration: duration,
            curve: Curves.linear,
          );
        } catch (_) {
          // If animation is interrupted (e.g. disposal), break loop
          break;
        }
      } else {
        // Already at target, yield briefly to prevent tight loop
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Handle user scroll interaction start
  void _handleDragStart() {
    if (widget.enableUserScroll && !isDragging) {
      // Stop any ongoing animation
      _scrollController.animateTo(
        _scrollController.position.pixels,
        duration: Duration.zero,
        curve: Curves.linear,
      );
      isDragging = true;
    }
  }

  // Handle user scroll interaction end
  void _handleDragEnd() {
    if (widget.enableUserScroll && isDragging) {
      // Safety checks before resuming
      if (!_scrollController.hasClients || !mounted) {
        isDragging = false;
        return;
      }

      // Cancel any existing pause timer
      _pauseTimer?.cancel();

      // Set a timer to resume animation after pauseDuration
      _pauseTimer = Timer(widget.pauseDuration, () {
        if (mounted) {
          isDragging = false;
          // Restart the scrolling from current position
          _startScrolling();
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
      // Also handle drag cancel to prevent stuck state
      onHorizontalDragCancel: () => _handleDragEnd(),

      // Use Listener to catch all pointer events if gesture detector misses
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
    } else if (widget.separatorBuilder != null) {
      // Separated implementation
      final int count = widget.itemCount ?? 0;

      // Safety check: handle empty or single item lists
      if (count == 0) {
        return const Row(children: []);
      }

      if (count == 1) {
        // Only one item, no separators needed
        return Row(
          children: [widget.itemBuilder!(context, 0)],
        );
      }

      // Generate items with separators
      return Row(
        children: List.generate(
          count * 2 - 1,
          (index) {
            final itemIndex = index ~/ 2;
            if (index.isEven) {
              // Safety check: ensure itemIndex is within bounds
              if (itemIndex < count) {
                return widget.itemBuilder!(context, itemIndex);
              }
              return const SizedBox.shrink();
            } else {
              // Safety check: ensure itemIndex is within bounds for separator
              if (itemIndex < count - 1) {
                return widget.separatorBuilder!(context, itemIndex);
              }
              return const SizedBox.shrink();
            }
          },
        ),
      );
    } else {
      // Create a row dynamically using itemBuilder
      final int count = widget.itemCount ?? 0;

      // Safety check: handle empty lists
      if (count == 0) {
        return const Row(children: []);
      }

      return Row(
        children: List.generate(
          count,
          (index) => widget.itemBuilder!(context, index),
        ),
      );
    }
  }
}
