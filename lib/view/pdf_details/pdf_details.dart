// lib/view/screens/project_details/pdf_details/pdf_details.dart
import 'dart:io';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/controllers/pdf_drawing/pdf_drawing_controller.dart';
import 'package:docu_site/view/pdf_details/support_widgets/review_pdf.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/custom_drop_down_widget.dart';
import 'package:docu_site/view/widget/custom_tag_field_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sheet/sheet.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../utils/time_stamp.dart';

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
  final ValueNotifier<bool> _isToolbarVisible = ValueNotifier(true);

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

  bool get _isDrawOrPensMode => selectedIndex == 2 || selectedIndex == 4;
  bool get _isAnnotateMode => selectedIndex == 1;
  bool get _isCameraMode => selectedIndex == 3;
  String get _currentModeTitle => annotationModes[selectedIndex]['title'] as String;

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
    _isToolbarVisible.dispose();
    super.dispose();
  }

  void _saveDrawings() {
    final data = drawing.toJson();
    debugPrint('Saved annotations/drawings: ${data.keys.length} pages');
  }

  Future<void> _handleCameraTap(Offset localPoint) async {
    if (!_isCameraMode) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PickImageSourceSheet(),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    // Add timestamp to the image
    final String timestampedImagePath = await TimestampUtils.addTimestampToImage(picked.path);

    drawing.addCameraPinFromScreen(localPoint, timestampedImagePath);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image with timestamp attached to this spot')),
      );
    }
  }

  // Handle tap in annotation mode to place a new annotation
  void _handleAnnotationTap(TapDownDetails details) {
    if (_isAnnotateMode) {
      drawing.placeNewAnnotation(details.localPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: "Back",
        actions: [
          Obx(() {
            final count = drawing.getCurrentPageStrokes().length
                + drawing.annotationsForPage(drawing.currentPageNumber.value).length
                + drawing.cameraPinsForPage(drawing.currentPageNumber.value).length;
            return count > 0
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: MyText(
                text: '$count items',
                size: 12,
                color: kSecondaryColor,
              ),
            )
                : const SizedBox.shrink();
          }),
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
            child: IgnorePointer(ignoring: !_isDrawOrPensMode,
              child: GetBuilder<PdfDrawingController>(
                builder: (_) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _isDrawOrPensMode
                        ? (details) => drawing.startNewStrokeFromScreen(details.localPosition, 1.0)
                        : null,
                    onPanUpdate: _isDrawOrPensMode
                        ? (details) => drawing.addPointFromScreen(details.localPosition, 1.0)
                        : null,
                    onPanEnd: _isDrawOrPensMode ? (_) => drawing.endStroke() : null,
                    child: CustomPaint(
                      painter: _EnhancedDocSpacePainter(controller: drawing),
                    ),
                  );
                },
              ),
            ),
          ),

          // ---------- Annotation Overlay ----------
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _handleAnnotationTap,
              child: _AnnotationOverlay(controller: drawing),
            ),
          ),

          // ---------- NEW: Camera Pins Overlay + tap-to-place ----------
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (d) async {
                if (_isCameraMode) {
                  await _handleCameraTap(d.localPosition);
                }
              },
              child: _CameraPinsOverlay(controller: drawing),
            ),
          ),

          // ---------- Dynamic Toolbar ----------
          if (_isDrawOrPensMode)
            _buildToolbar(
              toolbar: _DrawingToolbar(
                controller: drawing,
                onMinimize: () => _isToolbarVisible.value = false,
                modeTitle: _currentModeTitle,
              ),
            ),

          if (_isAnnotateMode)
            _buildToolbar(
              toolbar: _AnnotationToolbar(
                controller: drawing,
                onMinimize: () => _isToolbarVisible.value = false,
                modeTitle: _currentModeTitle,
              ),
            ),

          // Camera mode: show a small hint chip on the right
          if (_isCameraMode)
            Positioned(
              right: 16,
              top: kToolbarHeight + 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kBorderColor),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.camera_alt, size: 18),
                    SizedBox(width: 8),
                    Text('Tap the PDF to attach a photo'),
                  ],
                ),
              ),
            ),

          // ---------- Undo/Redo Toolbar ----------
          if (_isDrawOrPensMode || _isAnnotateMode || _isCameraMode)
            Positioned(
              left: 16,
              top: kToolbarHeight + 12,
              child: _UndoRedoToolbar(controller: drawing),
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
                  BoxShadow(color: kTertiaryColor.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, -4)),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: kBorderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: MyText(text: 'Annotation Modes: ', size: 16, weight: FontWeight.w500)),
                      Image.asset(annotationModes[selectedIndex]['image'] as String, height: 16),
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
                            _isToolbarVisible.value = true;

                            if (mode['title'] == 'Pens') {
                              drawing.setPenTool(PenToolType.ballpointPen);
                            } else if (mode['title'] == 'Draw') {
                              drawing.setPenTool(PenToolType.marker);
                            } else if (mode['title'] == 'Annotate') {
                              drawing.setAnnotationTool(AnnotationToolType.stickyNote);
                            } else if (mode['title'] == 'Camera') {
                              // Stay on this screen and use tap to place pins
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tap on the PDF to attach a photo')),
                              );
                            }
                          },
                          child: Container(
                            color: isSelected ? kSecondaryColor.withOpacity(0.05) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Image.asset(mode['image'] as String, height: 20),
                                const SizedBox(width: 10),
                                Expanded(child: MyText(text: mode['title'] as String, size: 16, weight: FontWeight.w500)),
                                if (isSelected) Image.asset(Assets.imagesTick, height: 20),
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

  Widget _buildToolbar({required Widget toolbar}) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isToolbarVisible,
      builder: (context, isVisible, child) {
        if (isVisible) {
          return Positioned(
            right: 16,
            top: kToolbarHeight + 12,
            child: toolbar,
          );
        } else {
          return Positioned(
            right: 16,
            top: kToolbarHeight + 12,
            child: _ToolMinimizeButton(
              onTap: () => _isToolbarVisible.value = true,
              modeTitle: _currentModeTitle,
            ),
          );
        }
      },
    );
  }
}

/// ===== CAMERA: Pins Overlay =====
class _CameraPinsOverlay extends StatelessWidget {
  final PdfDrawingController controller;
  const _CameraPinsOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final page = controller.currentPageNumber.value;
      final pins = controller.cameraPinsForPage(page);
      if (pins.isEmpty) return const SizedBox.shrink();

      final zoom = controller.currentZoom;
      final scroll = controller.currentScrollOffset;

      return Stack(
        children: pins.map((pin) {
          final screenOffset = pin.position.toScreen(scroll, zoom);
          return Positioned(
            left: screenOffset.dx - 16,
            top: screenOffset.dy - 16,
            child: GestureDetector(
              onTap: () => _showPinPreview(context, pin),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // Very transparent background
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12, // Lighter shadow
                      blurRadius: 3,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8), // More visible border
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.black.withOpacity(0.6), // More transparent icon
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  void _showPinPreview(BuildContext context, CameraPin pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PinPreviewSheet(pin: pin, controller: controller),
    );
  }
}

class _PinPreviewSheet extends StatelessWidget {
  final CameraPin pin;
  final PdfDrawingController controller;
  const _PinPreviewSheet({required this.pin, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt),
                const SizedBox(width: 8),
                const Text('Attached Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    controller.removeCameraPin(pin);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: File(pin.imagePath).existsSync()
                    ? Image.file(
                  File(pin.imagePath),
                  fit: BoxFit.contain, // Changed from BoxFit.cover
                )
                    : Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Text('Image not found')),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Added: ${pin.createdAt}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Pick source sheet
class _PickImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          children: [
            const Center(
              child: Text('Attach Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Use Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// **NEW: Annotation Overlay**
class _AnnotationOverlay extends StatelessWidget {
  final PdfDrawingController controller;
  const _AnnotationOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final page = controller.currentPageNumber.value;
      final annotations = controller.pageAnnotations[page] ?? [];
      final zoom = controller.currentZoom;
      final scroll = controller.currentScrollOffset;

      if (annotations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Stack(
        children: annotations.map((ann) {
          final screenOffset = ann.position.toScreen(scroll, zoom);
          final isSelected = controller.selectedAnnotation.value?.id == ann.id;

          return Positioned(
            left: screenOffset.dx,
            top: screenOffset.dy,
            child: GestureDetector(
              onTap: () => controller.selectAnnotation(ann),
              child: _AnnotationWidget(
                annotation: ann,
                zoom: zoom,
                isSelected: isSelected,
                onDrag: (delta) {
                  // Save undo state before drag starts (simple way)
                  controller.saveAnnotationUndoState(controller.currentPageNumber.value);

                  final newPositionScreen = screenOffset + delta;
                  final newPositionDoc = DocPoint.fromScreen(
                      newPositionScreen, scroll, zoom);
                  controller.updateAnnotation(ann, newPosition: newPositionDoc);
                },
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

/// **NEW: Individual Annotation Widget**
class _AnnotationWidget extends StatelessWidget {
  final PdfAnnotation annotation;
  final double zoom;
  final bool isSelected;
  final void Function(Offset delta) onDrag;

  const _AnnotationWidget({
    required this.annotation,
    required this.zoom,
    required this.isSelected,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = annotation.width * zoom;
    final effectiveHeight = annotation.height * zoom;

    return Draggable(
      data: annotation,
      feedback: Opacity(
        opacity: 0.6,
        child: _buildContent(effectiveWidth, effectiveHeight, isSelected: true),
      ),
      childWhenDragging: const SizedBox.shrink(),
      onDragUpdate: (details) => onDrag(details.delta),
      child: _buildContent(effectiveWidth, effectiveHeight, isSelected: isSelected),
    );
  }

  Widget _buildContent(double width, double height, {required bool isSelected}) {
    // Determine the content based on the annotation type
    Widget content;
    switch (annotation.type) {
      case AnnotationToolType.text:
        content = Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: annotation.color.withOpacity(0.1),
            border: Border.all(color: annotation.color, width: 1.0 * zoom),
            borderRadius: BorderRadius.circular(4),
          ),
          child: MyText(
            text: annotation.text.isEmpty ? 'Tap to edit text' : annotation.text,
            size: 14 * zoom,
            color: Colors.black,
            maxLines: 5,
            textOverflow: TextOverflow.ellipsis,
          ),
        );
        break;
      case AnnotationToolType.stickyNote:
        content = Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: annotation.color,
            borderRadius: BorderRadius.circular(8 * zoom),
            boxShadow: [
              BoxShadow(color: Colors.black38, blurRadius: 4 * zoom, offset: Offset(2 * zoom, 2 * zoom)),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.push_pin,
              size: 30 * zoom,
              color: Colors.black54,
            ),
          ),
        );
        break;
    }

    return Stack(
      children: [
        content,
        if (isSelected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: kSecondaryColor, width: 2),
                borderRadius: BorderRadius.circular(annotation.type == AnnotationToolType.stickyNote ? 8 * zoom : 4),
              ),
            ),
          ),
      ],
    );
  }
}

/// **NEW: Annotation Toolbar**
class _AnnotationToolbar extends StatelessWidget {
  const _AnnotationToolbar({
    required this.controller,
    required this.onMinimize,
    required this.modeTitle,
  });
  final PdfDrawingController controller;
  final VoidCallback onMinimize;
  final String modeTitle;

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
              // Header
              Row(
                children: [
                  MyText(
                    text: '$modeTitle Tools',
                    size: 14,
                    weight: FontWeight.w600,
                    color: kTertiaryColor,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen, size: 20),
                    tooltip: 'Minimize Toolbar',
                    onPressed: onMinimize,
                    padding: AppSizes.ZERO,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tool Selection
              Row(
                children: [
                  _AnnotationToolButton(
                    type: AnnotationToolType.stickyNote,
                    icon: Icons.push_pin,
                    title: 'Note',
                    isSelected: controller.selectedAnnotationTool.value == AnnotationToolType.stickyNote,
                    onTap: () => controller.setAnnotationTool(AnnotationToolType.stickyNote),
                  ),
                  const SizedBox(width: 12),
                  _AnnotationToolButton(
                    type: AnnotationToolType.text,
                    icon: Icons.text_fields,
                    title: 'Text Box',
                    isSelected: controller.selectedAnnotationTool.value == AnnotationToolType.text,
                    onTap: () => controller.setAnnotationTool(AnnotationToolType.text),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Color Selection
              _buildColorSelection(),
              const SizedBox(height: 16),

              // Delete button for selected annotation
              if (controller.selectedAnnotation.value != null)
                MyButton(
                  buttonText: 'Delete Annotation',
                  onTap: () => controller.removeAnnotation(controller.selectedAnnotation.value!),
                  bgColor: kRedColor,
                  height: 40,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Color',
          size: 14,
          weight: FontWeight.w600,
          color: kTertiaryColor,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: controller.availableColors.map((color) {
            final isSelected = controller.selectedColor.value.value == color.value;
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
}

class _AnnotationToolButton extends StatelessWidget {
  final AnnotationToolType type;
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnnotationToolButton({
    required this.type,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kSecondaryColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? kSecondaryColor : kBorderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: isSelected ? kSecondaryColor : kTertiaryColor),
              const SizedBox(height: 4),
              MyText(
                text: title,
                size: 12,
                color: isSelected ? kSecondaryColor : kTertiaryColor,
                weight: FontWeight.w600,
              ),
            ],
          ),
        ),
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
    final List<Offset> screenPoints = stroke.points.map((p) => p.toScreen(
      controller.currentScrollOffset,
      controller.currentZoom,
    )).toList();

    final path = Path();
    path.moveTo(screenPoints.first.dx, screenPoints.first.dy);

    for (int i = 1; i < screenPoints.length - 1; i++) {
      final p1 = screenPoints[i];
      final p2 = screenPoints[i + 1];

      final endP = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, endP.dx, endP.dy);
    }

    if (screenPoints.length > 1) {
      path.lineTo(screenPoints.last.dx, screenPoints.last.dy);
    }

    final basePaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = stroke.toolType == PenToolType.highlighter
          ? StrokeCap.square
          : StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // We only use the variable width drawing for pressure-sensitive tools (fountain/calligraphy/pencil)
    if (stroke.toolType == PenToolType.fountainPen ||
        stroke.toolType == PenToolType.calligraphyPen ||
        stroke.toolType == PenToolType.pencil) {
      if (stroke.points.length >= 2) {
        _drawVariableWidthStroke(canvas, stroke, basePaint);
        return;
      }
    }

    basePaint.strokeWidth = stroke.width * controller.currentZoom;

    if (stroke.toolType == PenToolType.pencil) {
      basePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    } else if (stroke.toolType == PenToolType.highlighter) {
      basePaint.blendMode = BlendMode.multiply;
    }

    canvas.drawPath(path, basePaint);
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

      final effectiveWidth = stroke.getEffectiveWidth(i) * controller.currentZoom;

      // FIXED: Create new paint with all properties copied manually
      final paint = Paint()
        ..color = basePaint.color
        ..style = PaintingStyle.stroke
        ..strokeCap = basePaint.strokeCap
        ..strokeJoin = basePaint.strokeJoin
        ..isAntiAlias = true
        ..strokeWidth = effectiveWidth;

      // Apply tool-specific effects
      if (stroke.toolType == PenToolType.pencil) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      } else if (stroke.toolType == PenToolType.highlighter) {
        paint.blendMode = BlendMode.multiply;
      }

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedDocSpacePainter old) => true;
}

// ===== Combined Drawing Toolbar =====
class _DrawingToolbar extends StatelessWidget {
  const _DrawingToolbar({
    required this.controller,
    required this.onMinimize,
    required this.modeTitle,
  });
  final PdfDrawingController controller;
  final VoidCallback onMinimize;
  final String modeTitle;

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
              // Header with Minimize Button
              Row(
                children: [
                  MyText(
                    text: '$modeTitle Tools',
                    size: 14,
                    weight: FontWeight.w600,
                    color: kTertiaryColor,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen, size: 20),
                    tooltip: 'Minimize Toolbar',
                    onPressed: onMinimize,
                    padding: AppSizes.ZERO,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tool selection
              _buildToolSelection(modeTitle),
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

  Widget _buildToolSelection(String modeTitle) {
    // Only show pen selection in "Pens" mode
    if (modeTitle != 'Pens') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Pen Type',
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
            final isSelected = controller.selectedColor.value.value == color.value;
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
    final Map<PenToolType, String> _toolNames = {
      PenToolType.ballpointPen: 'Ballpoint',
      PenToolType.fountainPen: 'Fountain',
      PenToolType.highlighter: 'Highlighter',
      PenToolType.pencil: 'Pencil',
      PenToolType.marker: 'Marker',
      PenToolType.calligraphyPen: 'Calligraphy',
      PenToolType.technicalPen: 'Technical',
    };
    final toolName = _toolNames[tool]!;

    return Tooltip(
      message: toolName,
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
              const SizedBox(height: 1),
              Text(
                toolName.substring(0, 3),
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
}

// ===== Minimized Toolbar Button =====
class _ToolMinimizeButton extends StatelessWidget {
  final VoidCallback onTap;
  final String modeTitle;

  const _ToolMinimizeButton({required this.onTap, required this.modeTitle});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Show $modeTitle Tools',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSecondaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.settings, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

// ===== Undo/Redo Toolbar (No changes, now used for all drawing modes) =====
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
                            color: controller.selectedColor.value.value == c.value ? kSecondaryColor : Colors.white,
                            width: 2,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
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