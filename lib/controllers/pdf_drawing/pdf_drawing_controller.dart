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
    if (PdfDrawingController._toolConfigs[toolType]?.supportsPressure == true &&
        pressureValues.isNotEmpty &&
        pointIndex < pressureValues.length) {
      return width * (0.5 + pressureValues[pointIndex] * 0.5);
    }
    return width;
  }
}

/// **NEW: Camera Pin model**
class CameraPin {
  CameraPin({
    required this.id,
    required this.position, // DocPoint
    required this.imagePath,
    required this.createdAt,
  });

  final String id;
  DocPoint position;
  String imagePath;
  DateTime createdAt;

  CameraPin clone() => CameraPin(
    id: id,
    position: position,
    imagePath: imagePath,
    createdAt: createdAt,
  );
}

/// **NEW: Annotation model** (kept from previous version)
class PdfAnnotation {
  PdfAnnotation({
    required this.id,
    required this.position, // DocPoint of the top-left corner
    required this.type,
    this.text = '',
    this.color = Colors.yellow,
    this.width = 150,
    this.height = 100,
  });

  final String id;
  DocPoint position;
  AnnotationToolType type;
  String text;
  Color color;
  double width;
  double height;

  PdfAnnotation clone() => PdfAnnotation(
    id: id,
    position: position,
    type: type,
    text: text,
    color: color,
    width: width,
    height: height,
  );
}

/// Professional pen tool types
enum PenToolType {
  ballpointPen,
  fountainPen,
  highlighter,
  pencil,
  marker,
  calligraphyPen,
  technicalPen,
}

/// **Annotation tool types**
enum AnnotationToolType {
  text,
  stickyNote,
}

enum DrawTool { pen, eraser, selection }

class PdfDrawingController extends GetxController {
  // --- Drawing State ---
  final pageStrokes = <int, List<DrawingStroke>>{}.obs;
  final _undoStacks = <int, List<List<DrawingStroke>>>{};
  final _redoStacks = <int, List<List<DrawingStroke>>>{};

  // --- Annotation State ---
  final pageAnnotations = <int, List<PdfAnnotation>>{}.obs;
  final _annUndoStacks = <int, List<List<PdfAnnotation>>>{};
  final _annRedoStacks = <int, List<List<PdfAnnotation>>>{};
  final Rx<AnnotationToolType> selectedAnnotationTool = AnnotationToolType.stickyNote.obs;
  Rx<PdfAnnotation?> selectedAnnotation = Rx<PdfAnnotation?>(null);

  // --- NEW: Camera pins per page + history ---
  final pageCameraPins = <int, List<CameraPin>>{}.obs;
  final _camUndoStacks = <int, List<List<CameraPin>>>{};
  final _camRedoStacks = <int, List<List<CameraPin>>>{};

  // --- UI/Tool State ---
  final Rx<DrawTool> tool = DrawTool.pen.obs;
  final Rx<PenToolType> selectedPenTool = PenToolType.ballpointPen.obs;
  final Rx<Color> selectedColor = Rx<Color>(Colors.red);
  final RxDouble strokeWidth = 3.0.obs;
  final RxDouble toolOpacity = 1.0.obs;
  final RxBool isDrawing = false.obs;
  final RxInt currentPageNumber = 1.obs;

  Offset currentScrollOffset = Offset.zero;
  double currentZoom = 1.0;

  static final Map<PenToolType, PenToolConfig> _toolConfigs = {
    PenToolType.ballpointPen: PenToolConfig(
      minWidth: 1.0, maxWidth: 5.0, defaultWidth: 2.0,
      supportsPressure: false, opacity: 1.0, strokeCap: StrokeCap.round,
    ),
    PenToolType.fountainPen: PenToolConfig(
      minWidth: 0.5, maxWidth: 8.0, defaultWidth: 3.0,
      supportsPressure: true, opacity: 1.0, strokeCap: StrokeCap.round,
    ),
    PenToolType.highlighter: PenToolConfig(
      minWidth: 10.0, maxWidth: 30.0, defaultWidth: 15.0,
      supportsPressure: false, opacity: 0.4, strokeCap: StrokeCap.square,
    ),
    PenToolType.pencil: PenToolConfig(
      minWidth: 0.5, maxWidth: 6.0, defaultWidth: 2.0,
      supportsPressure: true, opacity: 0.8, strokeCap: StrokeCap.round,
    ),
    PenToolType.marker: PenToolConfig(
      minWidth: 8.0, maxWidth: 25.0, defaultWidth: 12.0,
      supportsPressure: false, opacity: 0.7, strokeCap: StrokeCap.square,
    ),
    PenToolType.calligraphyPen: PenToolConfig(
      minWidth: 2.0, maxWidth: 15.0, defaultWidth: 5.0,
      supportsPressure: true, opacity: 1.0, strokeCap: StrokeCap.round,
    ),
    PenToolType.technicalPen: PenToolConfig(
      minWidth: 0.3, maxWidth: 3.0, defaultWidth: 1.0,
      supportsPressure: false, opacity: 1.0, strokeCap: StrokeCap.round,
    ),
  };

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

  

  // --- Drawing Methods ---
  void startNewStrokeFromScreen(Offset localPoint, [double pressure = 0.5]) {
    isDrawing.value = true;
    final page = currentPageNumber.value;
    final docPoint = DocPoint.fromScreen(localPoint, currentScrollOffset, currentZoom);
    _saveUndoState(page);

    final stroke = DrawingStroke(
      points: [docPoint],
      color: _getEffectiveColor(),
      width: strokeWidth.value,
      toolType: selectedPenTool.value,
      isEraser: tool.value == DrawTool.eraser,
      pressureValues: [pressure],
    );

    pageStrokes.putIfAbsent(page, () => <DrawingStroke>[]);
    pageStrokes[page]!.add(stroke);
    update();
  }

  void addPointFromScreen(Offset localPoint, [double pressure = 0.5]) {
    if (!isDrawing.value) return;
    final page = currentPageNumber.value;
    final strokes = pageStrokes[page];
    if (strokes == null || strokes.isEmpty) return;

    final docPoint = DocPoint.fromScreen(localPoint, currentScrollOffset, currentZoom);
    final currentStroke = strokes.last;

    currentStroke.points.add(docPoint);
    currentStroke.pressureValues.add(pressure);

    if (currentStroke.isEraser) {
      _saveUndoState(page);
      _eraseAtDocPoint(page, docPoint, radiusDocPx: max(8.0, strokeWidth.value) / currentZoom);
    }
    update();
  }

  void endStroke() {
    isDrawing.value = false;
    update();
  }

  // --- Annotation Methods ---
  List<PdfAnnotation> annotationsForPage(int page) => pageAnnotations[page] ?? const [];
  void setAnnotationTool(AnnotationToolType type) {
    selectedAnnotationTool.value = type;
    tool.value = DrawTool.selection;
    selectedAnnotation.value = null;
    update();
  }

  void placeNewAnnotation(Offset localPoint) {
    final page = currentPageNumber.value;
    final docPoint = DocPoint.fromScreen(localPoint, currentScrollOffset, currentZoom);
    saveAnnotationUndoState(page);

    final newAnnotation = PdfAnnotation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      position: docPoint,
      type: selectedAnnotationTool.value,
      color: selectedColor.value.withOpacity(1.0),
      text: selectedAnnotationTool.value == AnnotationToolType.text ? 'Enter text here' : '',
      width: selectedAnnotationTool.value == AnnotationToolType.text ? 250 : 150,
      height: selectedAnnotationTool.value == AnnotationToolType.text ? 40 : 150,
    );

    pageAnnotations.putIfAbsent(page, () => <PdfAnnotation>[]);
    pageAnnotations[page]!.add(newAnnotation);
    selectedAnnotation.value = newAnnotation;
    update();
  }

  void updateAnnotation(PdfAnnotation annotation, {DocPoint? newPosition, double? newWidth, double? newHeight}) {
    final page = currentPageNumber.value;
    saveAnnotationUndoState(page);

    if (newPosition != null) annotation.position = newPosition;
    if (newWidth != null) annotation.width = newWidth;
    if (newHeight != null) annotation.height = newHeight;

    pageAnnotations.refresh();
  }

  void selectAnnotation(PdfAnnotation? annotation) {
    selectedAnnotation.value = annotation;
    update();
  }

  void removeAnnotation(PdfAnnotation annotation) {
    final page = currentPageNumber.value;
    saveAnnotationUndoState(page);
    pageAnnotations[page]?.removeWhere((ann) => ann.id == annotation.id);
    selectedAnnotation.value = null;
    pageAnnotations.refresh();
    update();
  }

  // --- NEW: Camera Pins Methods ---
  List<CameraPin> cameraPinsForPage(int page) => pageCameraPins[page] ?? const [];

  void saveCameraUndoState(int page) {
    _camUndoStacks.putIfAbsent(page, () => []);
    _camRedoStacks.putIfAbsent(page, () => []);
    _camRedoStacks[page]!.clear();

    final current = pageCameraPins[page]?.map((e) => e.clone()).toList() ?? [];
    _camUndoStacks[page]!.add(current);
    if (_camUndoStacks[page]!.length > 50) {
      _camUndoStacks[page]!.removeAt(0);
    }
  }

  void addCameraPinFromScreen(Offset localPoint, String imagePath) {
    final page = currentPageNumber.value;
    saveCameraUndoState(page);

    final docPoint = DocPoint.fromScreen(localPoint, currentScrollOffset, currentZoom);
    final pin = CameraPin(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      position: docPoint,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    pageCameraPins.putIfAbsent(page, () => <CameraPin>[]);
    pageCameraPins[page]!.add(pin);
    update();
  }

  // Remove or move pin (optional helpers)
  void removeCameraPin(CameraPin pin) {
    final page = currentPageNumber.value;
    saveCameraUndoState(page);
    pageCameraPins[page]?.removeWhere((p) => p.id == pin.id);
    pageCameraPins.refresh();
    update();
  }

  // --- Tool & UI Management ---
  void usePen() => tool.value = DrawTool.pen;
  void useEraser() {
    if (tool.value != DrawTool.eraser) {
      _saveUndoState(currentPageNumber.value);
    }
    tool.value = DrawTool.eraser;
  }

  void useAnnotationSelector() {
    tool.value = DrawTool.selection;
    selectedAnnotation.value = null;
    update();
  }

  void setPenTool(PenToolType penTool) {
    selectedPenTool.value = penTool;
    final config = _toolConfigs[penTool]!;
    strokeWidth.value = config.defaultWidth;
    toolOpacity.value = config.opacity;
    setColor(selectedColor.value.withOpacity(1.0));
    tool.value = DrawTool.pen;
    update();
  }

  void setColor(Color c) {
    final config = _toolConfigs[selectedPenTool.value]!;
    final base = c.withOpacity(1.0);
    if (selectedPenTool.value == PenToolType.highlighter) {
      selectedColor.value = base.withOpacity(config.opacity);
    } else {
      selectedColor.value = base.withOpacity(toolOpacity.value);
    }
    update();
  }

  void setStrokeWidth(double w) => strokeWidth.value = w;

  void setOpacity(double opacity) {
    toolOpacity.value = opacity;
    final config = _toolConfigs[selectedPenTool.value]!;
    if (selectedPenTool.value != PenToolType.highlighter) {
      selectedColor.value = selectedColor.value.withOpacity(1.0).withOpacity(opacity);
    } else {
      selectedColor.value = selectedColor.value.withOpacity(1.0).withOpacity(config.opacity);
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

  PenToolConfig get currentToolConfig => _toolConfigs[selectedPenTool.value]!;
  Color _getEffectiveColor() {
    if (tool.value == DrawTool.eraser) return Colors.transparent;
    return selectedColor.value;
  }

  // --- Undo/Redo Management (Combined) ---
  void _saveUndoState(int page) {
    _undoStacks.putIfAbsent(page, () => []);
    _redoStacks.putIfAbsent(page, () => []);
    _redoStacks[page]!.clear();

    final currentStrokes = pageStrokes[page]?.map((s) => DrawingStroke(
      points: List.from(s.points),
      color: s.color,
      width: s.width,
      toolType: s.toolType,
      isEraser: s.isEraser,
      pressureValues: List.from(s.pressureValues),
    )).toList() ?? [];

    _undoStacks[page]!.add(currentStrokes);
    if (_undoStacks[page]!.length > 50) {
      _undoStacks[page]!.removeAt(0);
    }
  }

  void saveAnnotationUndoState(int page) {
    _annUndoStacks.putIfAbsent(page, () => []);
    _annRedoStacks.putIfAbsent(page, () => []);
    _annRedoStacks[page]!.clear();

    final currentAnnotations = pageAnnotations[page]?.map((ann) => ann.clone()).toList() ?? [];
    _annUndoStacks[page]!.add(currentAnnotations);

    if (_annUndoStacks[page]!.length > 50) {
      _annUndoStacks[page]!.removeAt(0);
    }
  }

  void undo() {
    final page = currentPageNumber.value;

    if ((_undoStacks[page]?.length ?? 0) > 0) {
      final currentStrokes = pageStrokes[page]?.map((s) => DrawingStroke(
        points: List.from(s.points), color: s.color, width: s.width,
        toolType: s.toolType, isEraser: s.isEraser, pressureValues: List.from(s.pressureValues),
      )).toList() ?? [];
      _redoStacks[page]!.add(currentStrokes);
      pageStrokes[page] = _undoStacks[page]!.removeLast();
    } else if ((_annUndoStacks[page]?.length ?? 0) > 0) {
      final currentAnnotations = pageAnnotations[page]?.map((ann) => ann.clone()).toList() ?? [];
      _annRedoStacks[page]!.add(currentAnnotations);
      pageAnnotations[page] = _annUndoStacks[page]!.removeLast();
    } else if ((_camUndoStacks[page]?.length ?? 0) > 0) {
      final currentPins = pageCameraPins[page]?.map((p) => p.clone()).toList() ?? [];
      _camRedoStacks[page]!.add(currentPins);
      pageCameraPins[page] = _camUndoStacks[page]!.removeLast();
    } else {
      return;
    }
    update();
  }

  void redo() {
    final page = currentPageNumber.value;

    if ((_redoStacks[page]?.length ?? 0) > 0) {
      final currentStrokes = pageStrokes[page]?.map((s) => DrawingStroke(
        points: List.from(s.points), color: s.color, width: s.width,
        toolType: s.toolType, isEraser: s.isEraser, pressureValues: List.from(s.pressureValues),
      )).toList() ?? [];
      _undoStacks[page]!.add(currentStrokes);
      pageStrokes[page] = _redoStacks[page]!.removeLast();
    } else if ((_annRedoStacks[page]?.length ?? 0) > 0) {
      final currentAnnotations = pageAnnotations[page]?.map((ann) => ann.clone()).toList() ?? [];
      _annUndoStacks[page]!.add(currentAnnotations);
      pageAnnotations[page] = _annRedoStacks[page]!.removeLast();
    } else if ((_camRedoStacks[page]?.length ?? 0) > 0) {
      final currentPins = pageCameraPins[page]?.map((p) => p.clone()).toList() ?? [];
      _camUndoStacks[page]!.add(currentPins);
      pageCameraPins[page] = _camRedoStacks[page]!.removeLast();
    } else {
      return;
    }
    update();
  }

  bool get canUndo {
    final page = currentPageNumber.value;
    return (_undoStacks[page]?.isNotEmpty ?? false) ||
        (_annUndoStacks[page]?.isNotEmpty ?? false) ||
        (_camUndoStacks[page]?.isNotEmpty ?? false);
  }

  bool get canRedo {
    final page = currentPageNumber.value;
    return (_redoStacks[page]?.isNotEmpty ?? false) ||
        (_annRedoStacks[page]?.isNotEmpty ?? false) ||
        (_camRedoStacks[page]?.isNotEmpty ?? false);
  }

  void clearCurrentPage() {
    final page = currentPageNumber.value;
    _saveUndoState(page);
    saveAnnotationUndoState(page);
    saveCameraUndoState(page);
    pageStrokes[page]?.clear();
    pageAnnotations[page]?.clear();
    pageCameraPins[page]?.clear();
    update();
  }

  // --- Erase Logic ---
  void _eraseAtDocPoint(int page, DocPoint p, {double radiusDocPx = 8.0}) {
    final strokes = pageStrokes[page];
    if (strokes == null || strokes.isEmpty) return;

    for (int i = strokes.length - 2; i >= 0; i--) {
      final s = strokes[i];
      if (_strokeHitTest(s, p, radiusDocPx)) {
        strokes.removeAt(i);
      }
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

  // --- Serialization ---
  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    // strokes
    pageStrokes.forEach((page, strokes) {
      out['$page'] = [
        ...(out['$page'] ?? []),
        ...strokes.map((s) => {
          'type': 'stroke',
          'color': s.color.value,
          'width': s.width,
          'toolType': s.toolType.index,
          'eraser': s.isEraser,
          'points': s.points.map((p) => p.toJson()).toList(),
          'pressureValues': s.pressureValues,
        })
      ];
    });

    // annotations
    pageAnnotations.forEach((page, annotations) {
      out['$page'] = [
        ...(out['$page'] ?? []),
        ...annotations.map((ann) => {
          'type': 'annotation',
          'id': ann.id,
          'annType': ann.type.index,
          'position': ann.position.toJson(),
          'text': ann.text,
          'color': ann.color.value,
          'width': ann.width,
          'height': ann.height,
        })
      ];
    });

    // camera pins
    pageCameraPins.forEach((page, pins) {
      out['$page'] = [
        ...(out['$page'] ?? []),
        ...pins.map((pin) => {
          'type': 'cameraPin',
          'id': pin.id,
          'position': pin.position.toJson(),
          'imagePath': pin.imagePath,
          'createdAt': pin.createdAt.millisecondsSinceEpoch,
        })
      ];
    });

    return out;
  }

  void fromJson(Map<String, dynamic> data) {
    pageStrokes.clear();
    pageAnnotations.clear();
    pageCameraPins.clear();

    data.forEach((k, v) {
      final page = int.tryParse(k);
      if (page == null) return;

      final List<DrawingStroke> strokes = [];
      final List<PdfAnnotation> annotations = [];
      final List<CameraPin> pins = [];

      for (final m in v as List) {
        final type = m['type'];
        if (type == 'stroke') {
          final color = Color(m['color'] as int);
          final width = (m['width'] as num).toDouble();
          final toolType = PenToolType.values[(m['toolType'] as num).toInt()];
          final eraser = (m['eraser'] as bool?) ?? false;
          final pts = (m['points'] as List).map((p) => DocPoint.fromJson(p as Map<String, dynamic>)).toList();
          final pressures = (m['pressureValues'] as List?)?.map((p) => (p as num).toDouble()).toList() ?? [];

          strokes.add(DrawingStroke(
            points: pts,
            color: color,
            width: width,
            toolType: toolType,
            isEraser: eraser,
            pressureValues: pressures,
          ));
        } else if (type == 'annotation') {
          final annType = AnnotationToolType.values[(m['annType'] as num).toInt()];
          final position = DocPoint.fromJson(m['position'] as Map<String, dynamic>);
          annotations.add(PdfAnnotation(
            id: m['id'] as String,
            position: position,
            type: annType,
            text: m['text'] as String,
            color: Color(m['color'] as int),
            width: (m['width'] as num).toDouble(),
            height: (m['height'] as num).toDouble(),
          ));
        } else if (type == 'cameraPin') {
          final position = DocPoint.fromJson(m['position'] as Map<String, dynamic>);
          pins.add(CameraPin(
            id: m['id'] as String,
            position: position,
            imagePath: m['imagePath'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num).toInt()),
          ));
        }
      }

      if (strokes.isNotEmpty) pageStrokes[page] = strokes;
      if (annotations.isNotEmpty) pageAnnotations[page] = annotations;
      if (pins.isNotEmpty) pageCameraPins[page] = pins;
    });
    update();
  }

  @override
  void onClose() {
    super.onClose();
  }
}

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
