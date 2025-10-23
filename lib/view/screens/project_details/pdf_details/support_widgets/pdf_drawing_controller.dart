// lib/view/screens/project_details/pdf_details/support_widgets/pdf_drawing_controller.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A point in **document-space** (not screen-space).
class DocPoint {
  final double x;
  final double y;
  const DocPoint(this.x, this.y);

  Offset toOffset() => Offset(x, y);

  static DocPoint fromScreen(Offset localPoint, Offset scrollOffset, double zoom) {
    return DocPoint(
      (localPoint.dx + scrollOffset.dx) / zoom,
      (localPoint.dy + scrollOffset.dy) / zoom,
    );
  }

  Offset toScreen(Offset currentScroll, double currentZoom) {
    return Offset(
      x * currentZoom - currentScroll.dx,
      y * currentZoom - currentScroll.dy,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  static DocPoint fromJson(Map<String, dynamic> json) =>
      DocPoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

/// Enhanced drawing stroke with pressure sensitivity support
class DrawingStroke {
  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.toolType,
    this.isEraser = false,
    this.pressureValues = const [],
  });

  final List<DocPoint> points;
  final Color color;
  final double width;
  final PenToolType toolType;
  final bool isEraser;
  final List<double> pressureValues;

  /// Get actual stroke width considering pressure
  double getEffectiveWidth(int pointIndex) {
    if (pressureValues.isEmpty || pointIndex >= pressureValues.length) {
      return width;
    }
    return width * (0.5 + pressureValues[pointIndex] * 0.5);
  }
}

/// Professional pen tool types
enum PenToolType {
  ballpointPen,    // Smooth, consistent line
  fountainPen,     // Variable width with pressure
  highlighter,     // Semi-transparent
  pencil,          // Textured, semi-transparent
  marker,          // Bold, opaque
  calligraphyPen,  // Angled tip effect
  technicalPen,    // Precise, consistent
}

enum DrawTool { pen, eraser, selection }

class PdfDrawingController extends GetxController {
  /// Per-page strokes (document-space)
  final pageStrokes = <int, List<DrawingStroke>>{}.obs;

  /// Undo/redo per page
  final _undoStacks = <int, List<List<DrawingStroke>>>{};
  final _redoStacks = <int, List<List<DrawingStroke>>>{};

  /// UI state
  final Rx<DrawTool> tool = DrawTool.pen.obs;
  final Rx<PenToolType> selectedPenTool = PenToolType.ballpointPen.obs;
  final Rx<Color> selectedColor = Colors.red.obs;
  final RxDouble strokeWidth = 3.0.obs;
  final RxDouble toolOpacity = 1.0.obs;
  final RxBool isDrawing = false.obs;
  final RxInt currentPageNumber = 1.obs;

  /// current viewer transform
  Offset currentScrollOffset = Offset.zero;
  double currentZoom = 1.0;

  /// Pen tool configurations
  static final Map<PenToolType, PenToolConfig> _toolConfigs = {
    PenToolType.ballpointPen: PenToolConfig(
      minWidth: 1.0,
      maxWidth: 5.0,
      defaultWidth: 2.0,
      supportsPressure: false,
      opacity: 1.0,
      strokeCap: StrokeCap.round,
    ),
    PenToolType.fountainPen: PenToolConfig(
      minWidth: 0.5,
      maxWidth: 8.0,
      defaultWidth: 3.0,
      supportsPressure: true,
      opacity: 1.0,
      strokeCap: StrokeCap.round,
    ),
    PenToolType.highlighter: PenToolConfig(
      minWidth: 10.0,
      maxWidth: 30.0,
      defaultWidth: 15.0,
      supportsPressure: false,
      opacity: 0.4,
      strokeCap: StrokeCap.square,
    ),
    PenToolType.pencil: PenToolConfig(
      minWidth: 0.5,
      maxWidth: 6.0,
      defaultWidth: 2.0,
      supportsPressure: true,
      opacity: 0.8,
      strokeCap: StrokeCap.round,
    ),
    PenToolType.marker: PenToolConfig(
      minWidth: 8.0,
      maxWidth: 25.0,
      defaultWidth: 12.0,
      supportsPressure: false,
      opacity: 0.7,
      strokeCap: StrokeCap.square,
    ),
    PenToolType.calligraphyPen: PenToolConfig(
      minWidth: 2.0,
      maxWidth: 15.0,
      defaultWidth: 5.0,
      supportsPressure: true,
      opacity: 1.0,
      strokeCap: StrokeCap.round,
    ),
    PenToolType.technicalPen: PenToolConfig(
      minWidth: 0.3,
      maxWidth: 3.0,
      defaultWidth: 1.0,
      supportsPressure: false,
      opacity: 1.0,
      strokeCap: StrokeCap.round,
    ),
  };

  /// Available colors for pens
  final List<Color> availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.yellow,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
  ];

  /// Begin a new stroke at a screen-local point
  void startNewStrokeFromScreen(Offset localPoint, [double pressure = 0.5]) {
    isDrawing.value = true;
    final page = currentPageNumber.value;
    final docPoint = DocPoint.fromScreen(localPoint, currentScrollOffset, currentZoom);

    final stroke = DrawingStroke(
      points: [docPoint],
      color: _getEffectiveColor(),
      width: strokeWidth.value,
      toolType: selectedPenTool.value,
      isEraser: tool.value == DrawTool.eraser,
      pressureValues: [pressure],
    );

    pageStrokes.putIfAbsent(page, () => <DrawingStroke>[]);

    // Save state for undo before adding new stroke
    _saveUndoState(page);

    pageStrokes[page]!.add(stroke);

    update();
  }

  /// Add to current stroke with a new screen-local point
  void addPointFromScreen(Offset localPoint, [double pressure = 0.5]) {
    if (!isDrawing.value) return;
    final page = currentPageNumber.value;
    final strokes = pageStrokes[page];
    if (strokes == null || strokes.isEmpty) return;

    final docPoint = DocPoint.fromScreen(localPoint, currentScrollOffset, currentZoom);
    final currentStroke = strokes.last;

    currentStroke.points.add(docPoint);
    currentStroke.pressureValues.add(pressure);

    // If eraser, we actively erase overlapping strokes on the fly
    if (currentStroke.isEraser) {
      _eraseAtDocPoint(page, docPoint, radiusDocPx: max(8.0, strokeWidth.value) / currentZoom);
    }

    update();
  }

  void endStroke() {
    isDrawing.value = false;
    update();
  }

  /// Tool management
  void usePen() => tool.value = DrawTool.pen;
  void useEraser() => tool.value = DrawTool.eraser;

  void setPenTool(PenToolType penTool) {
    selectedPenTool.value = penTool;
    final config = _toolConfigs[penTool]!;
    strokeWidth.value = config.defaultWidth;
    toolOpacity.value = config.opacity;

    // Set appropriate color for highlighter
    if (penTool == PenToolType.highlighter && selectedColor.value.alpha == 255) {
      selectedColor.value = selectedColor.value.withOpacity(0.4);
    }

    update();
  }

  void setColor(Color c) {
    final config = _toolConfigs[selectedPenTool.value]!;
    if (selectedPenTool.value == PenToolType.highlighter) {
      selectedColor.value = c.withOpacity(config.opacity);
    } else {
      selectedColor.value = c.withOpacity(toolOpacity.value);
    }
    update();
  }

  void setStrokeWidth(double w) => strokeWidth.value = w;
  void setOpacity(double opacity) {
    toolOpacity.value = opacity;
    if (selectedPenTool.value != PenToolType.highlighter) {
      selectedColor.value = selectedColor.value.withOpacity(opacity);
    }
    update();
  }

  void setCurrentPage(int pageNumber) {
    currentPageNumber.value = pageNumber;
    update();
  }

  void setViewerTransform({required Offset scroll, required double zoom}) {
    currentScrollOffset = scroll;
    currentZoom = zoom;
    update();
  }

  List<DrawingStroke> strokesForPage(int page) => pageStrokes[page] ?? const [];
  List<DrawingStroke> getCurrentPageStrokes() => strokesForPage(currentPageNumber.value);

  /// Get current tool configuration
  PenToolConfig get currentToolConfig => _toolConfigs[selectedPenTool.value]!;

  /// Get effective color considering tool type and opacity
  Color _getEffectiveColor() {
    if (tool.value == DrawTool.eraser) {
      return Colors.transparent;
    }

    final config = _toolConfigs[selectedPenTool.value]!;
    if (selectedPenTool.value == PenToolType.highlighter) {
      return selectedColor.value.withOpacity(config.opacity);
    }
    return selectedColor.value.withOpacity(toolOpacity.value);
  }

  /// Undo/Redo with proper state management
  void _saveUndoState(int page) {
    _undoStacks.putIfAbsent(page, () => []);
    _redoStacks.putIfAbsent(page, () => []);

    // Save current state
    final currentStrokes = List<DrawingStroke>.from(pageStrokes[page] ?? []);
    _undoStacks[page]!.add(currentStrokes);

    // Limit undo history
    if (_undoStacks[page]!.length > 50) {
      _undoStacks[page]!.removeAt(0);
    }
  }

  void undo() {
    final page = currentPageNumber.value;
    final undoStack = _undoStacks[page];
    if (undoStack == null || undoStack.isEmpty) return;

    _redoStacks.putIfAbsent(page, () => []);

    // Save current state to redo stack
    final currentStrokes = List<DrawingStroke>.from(pageStrokes[page] ?? []);
    _redoStacks[page]!.add(currentStrokes);

    // Restore previous state
    pageStrokes[page] = undoStack.removeLast();

    update();
  }

  void redo() {
    final page = currentPageNumber.value;
    final redoStack = _redoStacks[page];
    if (redoStack == null || redoStack.isEmpty) return;

    _undoStacks.putIfAbsent(page, () => []);

    // Save current state to undo stack
    final currentStrokes = List<DrawingStroke>.from(pageStrokes[page] ?? []);
    _undoStacks[page]!.add(currentStrokes);

    // Restore redone state
    pageStrokes[page] = redoStack.removeLast();

    update();
  }

  bool get canUndo {
    final page = currentPageNumber.value;
    return _undoStacks[page]?.isNotEmpty ?? false;
  }

  bool get canRedo {
    final page = currentPageNumber.value;
    return _redoStacks[page]?.isNotEmpty ?? false;
  }

  void clearCurrentPage() {
    final page = currentPageNumber.value;
    _saveUndoState(page);
    pageStrokes[page]?.clear();
    update();
  }

  void clearAll() {
    final page = currentPageNumber.value;
    _saveUndoState(page);
    pageStrokes.clear();
    _redoStacks.clear();
    update();
  }

  /// Enhanced eraser with different modes
  void _eraseAtDocPoint(int page, DocPoint p, {double radiusDocPx = 8.0}) {
    final strokes = pageStrokes[page];
    if (strokes == null || strokes.isEmpty) return;

    bool strokeRemoved = false;
    for (int i = strokes.length - 2; i >= 0; i--) {
      final s = strokes[i];
      if (_strokeHitTest(s, p, radiusDocPx)) {
        strokes.removeAt(i);
        strokeRemoved = true;
      }
    }
    if (strokeRemoved) {
      _redoStacks[page]?.clear();
    }
  }

  bool _strokeHitTest(DrawingStroke s, DocPoint p, double radius) {
    if (s.points.length < 2) return false;
    final r2 = radius * radius;
    for (int i = 0; i < s.points.length - 1; i++) {
      final a = s.points[i].toOffset();
      final b = s.points[i + 1].toOffset();
      final d = _distPointToSegmentSquared(p.toOffset(), a, b);
      if (d <= r2) return true;
    }
    return false;
  }

  double _distPointToSegmentSquared(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    double t = 0.0;
    if (len2 > 0.0) t = (ap.dx * ab.dx + ap.dy * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    final dx = p.dx - proj.dx;
    final dy = p.dy - proj.dy;
    return dx * dx + dy * dy;
  }

  // ----- Serialization -----
  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    pageStrokes.forEach((page, strokes) {
      out['$page'] = strokes.map((s) {
        return {
          'color': s.color.value,
          'width': s.width,
          'toolType': s.toolType.index,
          'eraser': s.isEraser,
          'points': s.points.map((p) => p.toJson()).toList(),
          'pressureValues': s.pressureValues,
        };
      }).toList();
    });
    return out;
  }

  void fromJson(Map<String, dynamic> data) {
    pageStrokes.clear();
    data.forEach((k, v) {
      final page = int.tryParse(k);
      if (page == null) return;
      final list = (v as List).map((m) {
        final color = Color(m['color'] as int);
        final width = (m['width'] as num).toDouble();
        final toolType = PenToolType.values[(m['toolType'] as num).toInt()];
        final eraser = (m['eraser'] as bool?) ?? false;
        final pts = (m['points'] as List).map((p) => DocPoint.fromJson(p)).toList();
        final pressures = (m['pressureValues'] as List?)?.map((p) => (p as num).toDouble()).toList() ?? [];

        return DrawingStroke(
          points: pts,
          color: color,
          width: width,
          toolType: toolType,
          isEraser: eraser,
          pressureValues: pressures,
        );
      }).toList();
      pageStrokes[page] = list;
    });
    update();
  }

  @override
  void onClose() {
    super.onClose();
  }
}

/// Configuration for different pen tools
class PenToolConfig {
  final double minWidth;
  final double maxWidth;
  final double defaultWidth;
  final bool supportsPressure;
  final double opacity;
  final StrokeCap strokeCap;

  const PenToolConfig({
    required this.minWidth,
    required this.maxWidth,
    required this.defaultWidth,
    required this.supportsPressure,
    required this.opacity,
    required this.strokeCap,
  });
}