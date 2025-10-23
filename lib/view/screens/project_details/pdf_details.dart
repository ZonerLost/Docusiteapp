// lib/view/screens/project_details/pdf_details/pdf_details.dart
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/project_details/pdf_details/support_widgets/pdf_drawing_controller.dart';
import 'package:docu_site/view/screens/project_details/pdf_open_camera.dart';
import 'package:docu_site/view/screens/project_details/review_pdf.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/custom_drop_down_widget.dart';
import 'package:docu_site/view/widget/custom_tag_field_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sheet/sheet.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfDetails extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final String? projectId;

  const PdfDetails({
    super.key,
    required this.fileUrl,
    required this.fileName,
    this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return _PdfDetailsSelectable(
      fileUrl: fileUrl,
      fileName: fileName,
      projectId: projectId,
    );
  }
}

class _PdfDetailsSelectable extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final String? projectId;

  const _PdfDetailsSelectable({
    super.key,
    required this.fileUrl,
    required this.fileName,
    this.projectId,
  });

  @override
  State<_PdfDetailsSelectable> createState() => _PdfDetailsSelectableState();
}

class _PdfDetailsSelectableState extends State<_PdfDetailsSelectable> {
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();
  final PdfViewerController _viewerController = PdfViewerController();
  final PdfDrawingController drawing = Get.put(PdfDrawingController());

  int selectedIndex = 0;
  bool _loadFailed = false;
  String? _loadErrorMessage;

  final annotationModes = const [
    {'image': Assets.imagesViewFile, 'title': 'View File'},
    {'image': Assets.imagesAnnotate, 'title': 'Annotate'},
    {'image': Assets.imagesDraw, 'title': 'Draw'},
    {'image': Assets.imagesCamera, 'title': 'Camera'},
    {'image': Assets.imagesPens, 'title': 'Pens'},
  ];

  bool get _isDrawMode => selectedIndex == 2;
  bool get _isPensMode => selectedIndex == 4;

  @override
  void initState() {
    super.initState();
    _viewerController.addListener(() {
      drawing.setViewerTransform(
        scroll: _viewerController.scrollOffset,
        zoom: _viewerController.zoomLevel,
      );
      drawing.setCurrentPage(_viewerController.pageNumber);
    });
  }

  @override
  void dispose() {
    _viewerController.removeListener(() {});
    super.dispose();
  }

  void _saveDrawings() {
    final data = drawing.toJson();
    debugPrint('Saved drawings: ${data.keys.length} pages');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: "Back",
        actions: [
          // Drawing info
          Obx(() => drawing.getCurrentPageStrokes().isNotEmpty
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kSecondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MyText(
              text: '${drawing.getCurrentPageStrokes().length} strokes',
              size: 12,
              color: kSecondaryColor,
            ),
          )
              : const SizedBox.shrink()),
          const SizedBox(width: 8),
          Center(
            child: SizedBox(
              width: 120,
              child: MyButton(
                buttonText: 'Save & Export',
                onTap: () {
                  _saveDrawings();
                  Get.bottomSheet(_ExportPDF(), isScrollControlled: true);
                },
                height: 36,
                textSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Stack(
        children: [
          // ---------- PDF ----------
          Positioned.fill(
            child: _loadFailed
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: kRedColor, size: 32),
                  const SizedBox(height: 8),
                  MyText(
                    text: _loadErrorMessage ?? 'Failed to load PDF.',
                    color: kQuaternaryColor,
                    size: 13,
                  ),
                ],
              ),
            )
                : SfPdfViewer.network(
              widget.fileUrl,
              key: _pdfKey,
              controller: _viewerController,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              onDocumentLoadFailed: (details) {
                setState(() {
                  _loadFailed = true;
                  _loadErrorMessage = details.description;
                });
              },
              onPageChanged: (d) => drawing.setCurrentPage(d.newPageNumber),
            ),
          ),

          // ---------- Drawing Overlay ----------
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !(_isDrawMode || _isPensMode),
              child: GetBuilder<PdfDrawingController>(
                builder: (_) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_isDrawMode || _isPensMode)
                        ? (details) => drawing.startNewStrokeFromScreen(details.localPosition)
                        : null,
                    onPanUpdate: (_isDrawMode || _isPensMode)
                        ? (details) => drawing.addPointFromScreen(details.localPosition)
                        : null,
                    onPanEnd: (_isDrawMode || _isPensMode)
                        ? (_) => drawing.endStroke()
                        : null,
                    child: CustomPaint(
                      painter: _EnhancedDocSpacePainter(controller: drawing),
                    ),
                  );
                },
              ),
            ),
          ),

          // ---------- Draw toolbar ----------
          if (_isDrawMode)
            Positioned(
              right: 16,
              top: kToolbarHeight + 12,
              child: _AddNotes(),
              // child: _DrawToolbar(controller: drawing),
            ),

          // ---------- Pens toolbar ----------
          if (_isPensMode)
            Positioned(
              right: 16,
              top: kToolbarHeight + 12,
              child: _AddNotes(),
              // child: _PensToolbar(controller: drawing),
            ),

          // ---------- Undo/Redo for both modes ----------
          if (_isDrawMode || _isPensMode)
            Positioned(
              left: 16,
              top: kToolbarHeight + 12,
              child: _UndoRedoToolbar(controller: drawing),
            ),

          // ---------- Existing decorative overlays ----------
          if (selectedIndex == 1)
            Positioned(
              top: 70,
              left: 30,
              child: Image.asset(Assets.imagesAnnotation, height: 200),
            ),
          if (!_isDrawMode && !_isPensMode)
            Center(
              child: _Marker(onTap: () {}, icon: Assets.imagesCameraOnPdf),
            ),
          if (selectedIndex == 1)
            Positioned(
              right: 20,
              bottom: 100,
              child: Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (index) {
                  final List<String> _items = [
                    Assets.imagesTt,
                    Assets.imagesEd,
                    Assets.imagesSave,
                    Assets.imagesUn,
                    Assets.imagesRe,
                  ];
                  return _Marker(onTap: () {}, icon: _items[index]);
                }),
              ),
            ),

          // ---------- Bottom modes ----------
          Sheet(
            initialExtent: 80,
            minExtent: 80,
            maxExtent: 280,
            child: Container(
              padding: AppSizes.DEFAULT,
              decoration: BoxDecoration(
                color: kFillColor,
                boxShadow: [
                  BoxShadow(
                    color: kTertiaryColor.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: kBorderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MyText(
                          text: 'Annotation Modes: ',
                          size: 16,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Image.asset(
                        annotationModes[selectedIndex]['image'] as String,
                        height: 16,
                      ),
                      const SizedBox(width: 8),
                      MyText(
                        text: annotationModes[selectedIndex]['title'] as String,
                        size: 16,
                        color: kSecondaryColor,
                        weight: FontWeight.w500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: annotationModes.length,
                      itemBuilder: (context, index) {
                        final mode = annotationModes[index];
                        final isSelected = selectedIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedIndex = index);
                            if (mode['title'] == 'Pens') {
                              // Initialize pens mode with default tool
                              drawing.setPenTool(PenToolType.ballpointPen);
                            } else if (mode['title'] == 'Camera') {
                              Get.to(() => PdfOpenCamera());
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? kSecondaryColor.withOpacity(0.05)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Image.asset(mode['image'] as String, height: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: MyText(
                                    text: mode['title'] as String,
                                    size: 16,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                if (isSelected)
                                  Image.asset(Assets.imagesTick, height: 20),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        color: kBorderColor,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced painter with professional pen rendering
class _EnhancedDocSpacePainter extends CustomPainter {
  final PdfDrawingController controller;
  _EnhancedDocSpacePainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final page = controller.currentPageNumber.value;
    final strokes = controller.strokesForPage(page);
    if (strokes.isEmpty) return;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      if (stroke.isEraser) continue;

      _drawStroke(canvas, stroke);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    final path = Path();
    final first = stroke.points.first.toScreen(
      controller.currentScrollOffset,
      controller.currentZoom,
    );
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i].toScreen(
        controller.currentScrollOffset,
        controller.currentZoom,
      );
      path.lineTo(point.dx, point.dy);
    }

    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = stroke.toolType == PenToolType.highlighter
          ? StrokeCap.square
          : StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Apply tool-specific rendering
    switch (stroke.toolType) {
      case PenToolType.pencil:
        paint.strokeWidth = stroke.width;
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
        break;
      case PenToolType.highlighter:
        paint.strokeWidth = stroke.width;
        paint.blendMode = BlendMode.multiply;
        break;
      case PenToolType.fountainPen:
      case PenToolType.calligraphyPen:
      // Variable width based on pressure
        if (stroke.points.length >= 2) {
          _drawVariableWidthStroke(canvas, stroke, paint);
          return;
        }
        paint.strokeWidth = stroke.width;
        break;
      default:
        paint.strokeWidth = stroke.width;
    }

    canvas.drawPath(path, paint);
  }

  void _drawVariableWidthStroke(Canvas canvas, DrawingStroke stroke, Paint basePaint) {
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final start = stroke.points[i].toScreen(
        controller.currentScrollOffset,
        controller.currentZoom,
      );
      final end = stroke.points[i + 1].toScreen(
        controller.currentScrollOffset,
        controller.currentZoom,
      );

      final width = stroke.getEffectiveWidth(i);
      final paint = basePaint..strokeWidth = width;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedDocSpacePainter old) => true;
}

// ===== Enhanced Pens Toolbar =====
class _PensToolbar extends StatelessWidget {
  const _PensToolbar({required this.controller});
  final PdfDrawingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Material(
        color: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tool selection
              _buildToolSelection(),
              const SizedBox(height: 16),

              // Color selection
              _buildColorSelection(),
              const SizedBox(height: 16),

              // Width and opacity controls
              _buildWidthOpacityControls(),
              const SizedBox(height: 16),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Pen Tools',
          size: 14,
          weight: FontWeight.w600,
          color: kTertiaryColor,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PenToolType.values.map((tool) {
            final isSelected = controller.selectedPenTool.value == tool;
            return _PenToolButton(
              tool: tool,
              isSelected: isSelected,
              onTap: () => controller.setPenTool(tool),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Colors',
          size: 14,
          weight: FontWeight.w600,
          color: kTertiaryColor,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: controller.availableColors.map((color) {
            final isSelected = controller.selectedColor.value == color;
            return _ColorCircle(
              color: color,
              isSelected: isSelected,
              onTap: () => controller.setColor(color),
              size: 28,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWidthOpacityControls() {
    final config = controller.currentToolConfig;
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.brush, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Width: ${controller.strokeWidth.value.toStringAsFixed(1)}',
                    size: 12,
                    color: kTertiaryColor,
                  ),
                  Slider(
                    min: config.minWidth,
                    max: config.maxWidth,
                    value: controller.strokeWidth.value,
                    onChanged: controller.setStrokeWidth,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.opacity, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Opacity: ${(controller.toolOpacity.value * 100).toInt()}%',
                    size: 12,
                    color: kTertiaryColor,
                  ),
                  Slider(
                    min: 0.1,
                    max: 1.0,
                    value: controller.toolOpacity.value,
                    onChanged: controller.setOpacity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.useEraser,
            icon: const Icon(Icons.auto_fix_off, size: 18),
            label: const Text('Eraser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kRedColor,
              side: BorderSide(color: kRedColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: controller.clearCurrentPage,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear'),
            style: FilledButton.styleFrom(
              backgroundColor: kRedColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _PenToolButton extends StatelessWidget {
  final PenToolType tool;
  final bool isSelected;
  final VoidCallback onTap;

  const _PenToolButton({
    required this.tool,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getToolConfig(tool);
    return Tooltip(
      message: _getToolName(tool),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? kSecondaryColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? kSecondaryColor : kBorderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getToolIcon(tool),
              const SizedBox(height: 2),
              Text(
                _getToolName(tool).substring(0, 3),
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected ? kSecondaryColor : kTertiaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getToolIcon(PenToolType tool) {
    switch (tool) {
      case PenToolType.ballpointPen:
        return const Icon(Icons.edit, size: 16);
      case PenToolType.fountainPen:
        return const Icon(Icons.brush, size: 16);
      case PenToolType.highlighter:
        return const Icon(Icons.highlight, size: 16);
      case PenToolType.pencil:
        return const Icon(Icons.draw, size: 16);
      case PenToolType.marker:
        return const Icon(Icons.format_paint, size: 16);
      case PenToolType.calligraphyPen:
        return const Icon(Icons.brush_outlined, size: 16);
      case PenToolType.technicalPen:
        return const Icon(Icons.architecture, size: 16);
    }
  }

  String _getToolName(PenToolType tool) {
    switch (tool) {
      case PenToolType.ballpointPen: return 'Ballpoint';
      case PenToolType.fountainPen: return 'Fountain';
      case PenToolType.highlighter: return 'Highlighter';
      case PenToolType.pencil: return 'Pencil';
      case PenToolType.marker: return 'Marker';
      case PenToolType.calligraphyPen: return 'Calligraphy';
      case PenToolType.technicalPen: return 'Technical';
    }
  }

  PenToolConfig _getToolConfig(PenToolType tool) {
    final configs = {
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
    return configs[tool]!;
  }
}

// ===== Undo/Redo Toolbar =====
class _UndoRedoToolbar extends StatelessWidget {
  const _UndoRedoToolbar({required this.controller});
  final PdfDrawingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolActionButton(
                icon: Icons.undo,
                tooltip: 'Undo',
                onTap: controller.canUndo ? controller.undo : null,
                isEnabled: controller.canUndo,
              ),
              const SizedBox(width: 4),
              _ToolActionButton(
                icon: Icons.redo,
                tooltip: 'Redo',
                onTap: controller.canRedo ? controller.redo : null,
                isEnabled: controller.canRedo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _ToolActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isEnabled ? kSecondaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isEnabled ? kSecondaryColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ===== Reusable UI Components =====

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep your existing _DrawToolbar, _Marker, and bottom sheet classes...
// [The rest of your existing classes remain the same]

class _DrawToolbar extends StatelessWidget {
  const _DrawToolbar({required this.controller});
  final PdfDrawingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tool toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toolButton(
                    icon: Icons.brush,
                    selected: controller.tool.value == DrawTool.pen,
                    onTap: controller.usePen,
                  ),
                  const SizedBox(width: 6),
                  _toolButton(
                    icon: Icons.auto_fix_off,
                    selected: controller.tool.value == DrawTool.eraser,
                    onTap: controller.useEraser,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Colors
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final c in [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.black])
                    GestureDetector(
                      onTap: () => controller.setColor(c),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: controller.selectedColor.value == c ? kSecondaryColor : Colors.white,
                            width: 2,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Width slider
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.brush, size: 16, color: Colors.black54),
                  SizedBox(
                    width: 120,
                    child: Slider(
                      min: 1.0,
                      max: 16.0,
                      divisions: 15,
                      value: controller.strokeWidth.value,
                      onChanged: controller.setStrokeWidth,
                    ),
                  ),
                ],
              ),
              const Divider(height: 8),

              // Undo / Redo / Clear
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Undo',
                    icon: const Icon(Icons.undo),
                    onPressed: controller.undo,
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    icon: const Icon(Icons.redo),
                    onPressed: controller.redo,
                  ),
                  IconButton(
                    tooltip: 'Clear page',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: controller.clearCurrentPage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton({required IconData icon, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? kSecondaryColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? kSecondaryColor : kBorderColor),
        ),
        child: Icon(icon, size: 18, color: selected ? kSecondaryColor : Colors.black87),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.onTap, required this.icon});
  final VoidCallback onTap;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kTertiaryColor.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(icon, height: 52),
      ),
    );
  }
}

// ----- Bottom sheets kept as in your version -----

class _AddNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.5,
      margin: const EdgeInsets.only(top: 55),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(text: 'Add Notes', size: 18, weight: FontWeight.w500, paddingBottom: 8),
           MyText(text: 'Add important notes to this annotation.', color: kQuaternaryColor, weight: FontWeight.w500, size: 13),
          Container(height: 1, color: kBorderColor, margin: const EdgeInsets.symmetric(vertical: 12)),
           Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: BouncingScrollPhysics(),
              children: [
                SimpleTextField(labelText: 'Notes', hintText: 'Add your notes here', maxLines: 5),
              ],
            ),
          ),
          MyButton(buttonText: 'Add', onTap: Get.back),
        ],
      ),
    );
  }
}

class _ExportPDF extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.8,
      margin: const EdgeInsets.only(top: 55),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(text: 'Add Info', size: 18, weight: FontWeight.w500, paddingBottom: 8),
           MyText(text: 'Please enter the correct information to export a pdf.', color: kQuaternaryColor, weight: FontWeight.w500, size: 13),
          Container(height: 1, color: kBorderColor, margin: const EdgeInsets.symmetric(vertical: 12)),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: const BouncingScrollPhysics(),
              children: [
                 SimpleTextField(labelText: 'Project location', hintText: 'St 3 Wilsons Road, California, USA'),
                 CustomDropDown(
                  labelText: 'Status',
                  hintText: 'Select status',
                  items: ['Select status', 'In Progress', 'Completed', 'Pending'],
                  selectedValue: 'In Progress',
                  onChanged: null,
                ),
                Row(
                  children: [
                     Expanded(
                      child: MyText(text: 'Assign Members', size: 14, weight: FontWeight.w500, color: kQuaternaryColor),
                    ),
                    MyText(
                      onTap: () => Get.bottomSheet(_InviteNewMember(), isScrollControlled: true),
                      text: '+ Invite new member',
                      size: 14,
                      weight: FontWeight.w500,
                      color: kSecondaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const CustomTagField(),
                 SimpleTextField(labelText: 'Description', hintText: 'Lorem ipsum dolor aist amaet', maxLines: 3),
                 SimpleTextField(labelText: 'Conclusion', hintText: 'Lorem ipsum dolor aist amaet', maxLines: 3),
              ],
            ),
          ),
          MyButton(
            buttonText: 'Continue',
            onTap: () {
              Get.back();
              Get.to(() => ReviewPdf());
            },
          ),
        ],
      ),
    );
  }
}

class _InviteNewMember extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.5,
      margin: const EdgeInsets.only(top: 55),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(text: 'Invite new member', size: 18, weight: FontWeight.w500, paddingBottom: 8),
           MyText(text: 'Please enter the correct information to add a new member.', color: kQuaternaryColor, weight: FontWeight.w500, size: 13),
          Container(height: 1, color: kBorderColor, margin: const EdgeInsets.symmetric(vertical: 12)),
           Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: BouncingScrollPhysics(),
              children: [
                SimpleTextField(labelText: 'Member Name', hintText: 'Chris Taylor'),
                SimpleTextField(labelText: 'Member email address', hintText: 'chris345@gmail.com'),
              ],
            ),
          ),
          MyButton(buttonText: 'Send Invite ', onTap: Get.back),
        ],
      ),
    );
  }
}
