import 'package:flutter/material.dart';
import '../theme/netra_theme.dart';

/// Interactive Resizable Split Row with Draggable Divider.
/// Allows side-by-side widgets to be resized horizontally by dragging the divider.
class ResizableSplitRow extends StatefulWidget {
  final Widget? leftChild;
  final Widget? rightChild;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final double spacing;
  final double collapseBreakpoint;

  const ResizableSplitRow({
    super.key,
    this.leftChild,
    this.rightChild,
    this.initialRatio = 0.55,
    this.minRatio = 0.20,
    this.maxRatio = 0.80,
    this.spacing = 16.0,
    this.collapseBreakpoint = 760.0,
  });

  @override
  State<ResizableSplitRow> createState() => _ResizableSplitRowState();
}

class _ResizableSplitRowState extends State<ResizableSplitRow> {
  late double _ratio;
  bool _isHovering = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  void _reset() {
    setState(() {
      _ratio = widget.initialRatio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);

    if (widget.leftChild == null && widget.rightChild == null) {
      return const SizedBox.shrink();
    }
    if (widget.leftChild != null && widget.rightChild == null) {
      return widget.leftChild!;
    }
    if (widget.leftChild == null && widget.rightChild != null) {
      return widget.rightChild!;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        // If screen is too narrow, stack vertically
        if (totalWidth < widget.collapseBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              widget.leftChild!,
              SizedBox(height: widget.spacing),
              widget.rightChild!,
            ],
          );
        }

        const dividerWidth = 14.0;
        final availableWidth = totalWidth - dividerWidth - (widget.spacing * 2);
        final leftWidth = (availableWidth * _ratio).clamp(
          availableWidth * widget.minRatio,
          availableWidth * widget.maxRatio,
        );
        final rightWidth = (availableWidth - leftWidth).clamp(
          availableWidth * (1.0 - widget.maxRatio),
          availableWidth * (1.0 - widget.minRatio),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Widget
            SizedBox(
              width: leftWidth,
              child: widget.leftChild!,
            ),
            SizedBox(width: widget.spacing / 2),

            // Draggable Divider
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _reset,
                onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    final newRatio = _ratio + (details.delta.dx / availableWidth);
                    _ratio = newRatio.clamp(widget.minRatio, widget.maxRatio);
                  });
                },
                child: Tooltip(
                  message: 'Drag left/right to resize • Double-click to reset (${(_ratio * 100).toInt()}% / ${(100 - _ratio * 100).toInt()}%)',
                  waitDuration: const Duration(milliseconds: 400),
                  child: Container(
                    width: dividerWidth,
                    height: 80,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _isHovering || _isDragging ? 6 : 3,
                      height: _isHovering || _isDragging ? 54 : 32,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? colors.primary
                            : (_isHovering ? colors.primary.withValues(alpha: 0.7) : colors.border),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: (_isHovering || _isDragging)
                            ? [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: widget.spacing / 2),

            // Right Widget
            SizedBox(
              width: rightWidth,
              child: widget.rightChild!,
            ),
          ],
        );
      },
    );
  }
}

/// Interactive Resizable Card Container.
/// Allows vertical height adjustment via a sleek bottom resize handle with drag feedback,
/// size presets, collapsible folding ("collide"), and optional removal.
class ResizableCard extends StatefulWidget {
  final Widget child;
  final double? initialHeight;
  final double minHeight;
  final double maxHeight;
  final String? title;
  final IconData? icon;
  final List<Widget>? headerActions;
  final EdgeInsetsGeometry padding;
  final bool isCollapsible;
  final bool initiallyCollapsed;
  final bool? isCollapsed;
  final ValueChanged<bool>? onCollapseChanged;
  final VoidCallback? onRemove;
  final Widget? collapsedSummary;

  const ResizableCard({
    super.key,
    required this.child,
    this.initialHeight,
    this.minHeight = 160.0,
    this.maxHeight = 900.0,
    this.title,
    this.icon,
    this.headerActions,
    this.padding = const EdgeInsets.all(20.0),
    this.isCollapsible = true,
    this.initiallyCollapsed = false,
    this.isCollapsed,
    this.onCollapseChanged,
    this.onRemove,
    this.collapsedSummary,
  });

  @override
  State<ResizableCard> createState() => _ResizableCardState();
}

class _ResizableCardState extends State<ResizableCard> {
  double? _height;
  bool _isHovering = false;
  bool _isDragging = false;
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight;
    _collapsed = widget.isCollapsed ?? widget.initiallyCollapsed;
  }

  @override
  void didUpdateWidget(covariant ResizableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != null && widget.isCollapsed != oldWidget.isCollapsed) {
      _collapsed = widget.isCollapsed!;
    }
  }

  void _resetHeight() {
    setState(() {
      _height = widget.initialHeight;
    });
  }

  void _setPreset(double? height) {
    setState(() {
      _height = height;
    });
  }

  void _toggleCollapse() {
    final next = !_collapsed;
    setState(() {
      _collapsed = next;
    });
    widget.onCollapseChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isDragging ? colors.primary.withValues(alpha: 0.6) : colors.border,
        ),
        boxShadow: _isDragging
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header if title is provided
          if (widget.title != null) ...[
            InkWell(
              onTap: widget.isCollapsible ? _toggleCollapse : null,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(14),
                bottom: _collapsed ? const Radius.circular(14) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: colors.primary, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.title!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_collapsed && widget.collapsedSummary != null) ...[
                            const SizedBox(width: 10),
                            Flexible(child: widget.collapsedSummary!),
                          ],
                        ],
                      ),
                    ),
                    if (!_collapsed && widget.headerActions != null) ...widget.headerActions!,
                    if (!_collapsed) ...[
                      // Quick Size Presets Menu
                      PopupMenuButton<double?>(
                        tooltip: 'Widget Size Presets',
                        icon: Icon(Icons.aspect_ratio, size: 16, color: colors.textSecondary),
                        color: colors.surfaceCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: colors.border),
                        ),
                        onSelected: _setPreset,
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: null,
                            child: Text('Auto Fit Content', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                          ),
                          PopupMenuItem(
                            value: 240.0,
                            child: Text('Compact (240px)', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                          ),
                          PopupMenuItem(
                            value: 380.0,
                            child: Text('Medium (380px)', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                          ),
                          PopupMenuItem(
                            value: 580.0,
                            child: Text('Large (580px)', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                    if (widget.isCollapsible)
                      Tooltip(
                        message: _collapsed ? 'Expand section' : 'Collapse section (collide)',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedRotation(
                            turns: _collapsed ? 0.0 : 0.5,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    if (widget.onRemove != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Hide from dashboard',
                        child: InkWell(
                          onTap: widget.onRemove,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!_collapsed)
              Divider(color: colors.border, height: 1),
          ],

          if (!_collapsed) ...[
            // Content Box (Scrollable if height is constrained)
            Padding(
              padding: widget.padding,
              child: _height == null
                  ? widget.child
                  : SizedBox(
                      height: _height,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: widget.child,
                      ),
                    ),
            ),

            // Bottom Drag Resize Handle
            MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _resetHeight,
                onVerticalDragStart: (_) {
                  setState(() {
                    _isDragging = true;
                    _height ??= widget.minHeight + 100.0;
                  });
                },
                onVerticalDragEnd: (_) => setState(() => _isDragging = false),
                onVerticalDragUpdate: (details) {
                  setState(() {
                    final cur = _height ?? (widget.minHeight + 100.0);
                    final next = cur + details.delta.dy;
                    _height = next.clamp(widget.minHeight, widget.maxHeight);
                  });
                },
                child: Tooltip(
                  message: _height != null
                      ? 'Drag vertically to resize (${_height!.toInt()}px) • Double-click to reset'
                      : 'Drag vertically to resize height • Double-click to reset',
                  waitDuration: const Duration(milliseconds: 300),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: _isDragging || _isHovering
                          ? colors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: _isDragging || _isHovering ? 48 : 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? colors.primary
                                : (_isHovering ? colors.primary.withValues(alpha: 0.8) : colors.border),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        if (_isDragging && _height != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${_height!.toInt()} px',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Interactive Resizable Sidebar Layout.
/// Wraps the sidebar and main content with a draggable vertical divider.
class ResizableSidebarLayout extends StatefulWidget {
  final Widget Function(BuildContext context, double width, bool isCollapsed) sidebarBuilder;
  final Widget content;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;

  const ResizableSidebarLayout({
    super.key,
    required this.sidebarBuilder,
    required this.content,
    this.initialWidth = 250.0,
    this.minWidth = 180.0,
    this.maxWidth = 420.0,
  });

  @override
  State<ResizableSidebarLayout> createState() => _ResizableSidebarLayoutState();
}

class _ResizableSidebarLayoutState extends State<ResizableSidebarLayout> {
  late double _width;
  bool _isHovering = false;
  bool _isDragging = false;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  void _resetWidth() {
    setState(() {
      _width = widget.initialWidth;
      _isCollapsed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = NetraColors.of(context);
    final effectiveWidth = _isCollapsed ? 76.0 : _width;

    return Row(
      children: [
        // Sidebar Container
        SizedBox(
          width: effectiveWidth,
          child: widget.sidebarBuilder(context, effectiveWidth, _isCollapsed),
        ),

        // Draggable Split Divider
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: _resetWidth,
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            onHorizontalDragUpdate: (details) {
              if (_isCollapsed) {
                if (details.delta.dx > 0) {
                  setState(() {
                    _isCollapsed = false;
                    _width = (widget.minWidth + details.delta.dx).clamp(widget.minWidth, widget.maxWidth);
                  });
                }
                return;
              }
              setState(() {
                final next = _width + details.delta.dx;
                if (next < widget.minWidth - 30) {
                  _isCollapsed = true;
                } else {
                  _width = next.clamp(widget.minWidth, widget.maxWidth);
                }
              });
            },
            child: Tooltip(
              message: _isCollapsed
                  ? 'Drag right to expand sidebar • Double-click to reset'
                  : 'Drag to resize sidebar (${_width.toInt()}px) • Double-click to reset',
              waitDuration: const Duration(milliseconds: 300),
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  color: _isDragging
                      ? colors.primary.withValues(alpha: 0.15)
                      : (_isHovering ? colors.primary.withValues(alpha: 0.08) : Colors.transparent),
                  border: Border(
                    left: BorderSide(
                      color: _isDragging
                          ? colors.primary
                          : (_isHovering ? colors.primary.withValues(alpha: 0.6) : colors.border),
                      width: _isDragging || _isHovering ? 2.0 : 1.0,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 3,
                  height: _isHovering || _isDragging ? 48 : 24,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? colors.primary
                        : (_isHovering ? colors.primary.withValues(alpha: 0.7) : Colors.transparent),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Main View Area
        Expanded(
          child: widget.content,
        ),
      ],
    );
  }
}

