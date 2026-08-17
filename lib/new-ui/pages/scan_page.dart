import 'dart:math';
import 'dart:ui';

import 'package:cake_wallet/core/qr_validator.dart';
import 'package:cake_wallet/entities/qr_scanner.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/scan_page/network_list.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/floating_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:fast_scanner/fast_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:ur/ur_decoder.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({
    super.key,
    this.showHelp = false,
    this.showManualInput = true,
    this.currentSymbol,
  });

  final bool showHelp;
  final bool showManualInput;
  final String? currentSymbol;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  int? _numCameras;
  bool _frontFlashMode = false;
  bool _textInputMode = false;
  final TextEditingController textController = TextEditingController();
  final FocusNode textFocusNode = FocusNode();
  List<String> urCodes = [];
  late var ur = URQRToURQRData(urCodes);
  final decoder = URDecoder();
  bool popped = false;
  Barcode? _barcode;

  // Animación de escaneo con marca Mi Bóveda.
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  bool _isProcessing = false;
  QrValidationResult? _lastValidation;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (mounted) {
        setState(() {
          _numCameras = controller.value.availableCameras;
        });
      }
    });

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    controller.dispose();
    textController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (_isProcessing) return;
    try {
      _handleBarcodeInternal(barcodes);
    } catch (e, st) {
      showPopUp<void>(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: S.of(context).error,
          alertContent: S.of(context).error_dialog_content,
          buttonText: 'ok',
          buttonAction: () => Navigator.of(context).pop(),
        ),
      );
      printV("$e\n$st");
    }
  }

  void _handleBarcodeInternal(BarcodeCapture barcodes) {
    for (final barcode in barcodes.barcodes) {
      if (barcode.rawValue?.trim().isEmpty ?? false == false) continue;
      if (barcode.rawValue!.startsWith("ur:")) {
        if (urCodes.contains(barcode.rawValue)) continue;
        decoder.receivePart(barcode.rawValue!);
        setState(() {
          urCodes.add(barcode.rawValue!);
          ur = URQRToURQRData(urCodes);
        });
        if (decoder.estimatedPercentComplete() == 1) {
          setState(() {
            popped = true;
          });
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(ur.inputs.join("\n"));
          });
        }
        return;
      }
    }
    if (urCodes.isNotEmpty) return;

    // QR normal: validar antes de aceptar.
    final raw = barcodes.barcodes.firstOrNull?.rawValue;
    if (raw == null || popped) return;

    setState(() {
      _isProcessing = true;
    });
    final validation = validateQrContent(raw, currentSymbol: widget.currentSymbol);

    setState(() {
      _lastValidation = validation;
      _isProcessing = false;
    });

    if (validation.isDangerous) {
      _showValidationAlert(validation);
      return;
    }

    if (validation.isValid) {
      setState(() {
        popped = true;
      });
      Navigator.of(context).pop(validation.address ?? raw);
    } else {
      _showValidationAlert(validation);
    }
  }

  void _showValidationAlert(QrValidationResult result) {
    showPopUp<void>(
      context: context,
      builder: (context) => AlertWithOneAction(
        alertTitle: result.isValid ? 'Código detectado' : 'Código no válido',
        alertContent: result.message,
        buttonText: 'Entendido',
        buttonAction: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cutoutSize = MediaQuery.of(context).size.width * 0.8;
    const double cutoutRadius = 24.0;
    const Duration textModeSwitchDuration = Duration(milliseconds: 300);
    final buttonColor = _frontFlashMode ? Colors.black.withAlpha(40) : Colors.white.withAlpha(40);
    final buttonIconColor = _frontFlashMode ? Colors.black : Colors.white;
    final isScanningURQR = decoder.processedPartsCount() > 0;
    final double targetRadius = isScanningURQR ? (cutoutSize / 2) : cutoutRadius;

    // Colores de marca Mi Bóveda.
    const brandPrimary = Color(0xFF6C5CE7);
    const brandSecondary = Color(0xFF00CEC9);
    const brandAccent = Color(0xFFFD79A8);

    return Material(
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),

          // Overlay oscuro con recorte animado.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _textInputMode = false;
              }),
              child: RepaintBoundary(
                child: AnimatedSwitcher(
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInQuad,
                  duration: textModeSwitchDuration,
                  child: _textInputMode
                      ? BackdropFilter(
                          key: const ValueKey(1),
                          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                          child: Container(
                            color: _frontFlashMode ? Colors.white : Colors.black.withAlpha(153),
                          ),
                        )
                      : TweenAnimationBuilder<double>(
                          key: const ValueKey(0),
                          tween: Tween<double>(begin: 0.0, end: targetRadius),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                            child: Container(
                              color: _frontFlashMode ? Colors.white : Colors.black.withAlpha(153),
                            ),
                          ),
                          builder: (context, radius, child) {
                            return ClipPath(
                              clipper: HoleClipper(
                                width: cutoutSize,
                                height: cutoutSize,
                                radius: radius,
                              ),
                              child: child,
                            );
                          },
                        ),
                ),
              ),
            ),
          ),

          // Borde del recorte con colores de marca.
          AnimatedOpacity(
            opacity: _textInputMode || isScanningURQR ? 0 : 1,
            duration: textModeSwitchDuration,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: targetRadius),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, radius, child) => Center(
                child: Container(
                  width: cutoutSize,
                  height: cutoutSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: brandPrimary,
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: brandPrimary.withAlpha(40),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Línea de escaneo animada con degradado de marca.
          if (!_textInputMode && !isScanningURQR)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                final double y = _scanLineAnimation.value * cutoutSize;
                return Center(
                  child: SizedBox(
                    width: cutoutSize,
                    height: cutoutSize,
                    child: Stack(
                      children: [
                        Positioned(
                          top: y,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [brandPrimary, brandSecondary, brandAccent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brandPrimary.withAlpha(80),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Logo Mi Bóveda en el centro del escáner.
          if (!_textInputMode && !isScanningURQR)
            Center(
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/mi_boveda_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white70,
                    size: 32,
                  ),
                ),
              ),
            ),

          // Header con controles.
          SafeArea(
            child: Column(
              children: [
                ModalTopBar(
                  title: "",
                  trailingWidget: AnimatedOpacity(
                    duration: textModeSwitchDuration,
                    opacity: _textInputMode ? 0 : 1,
                    child: Row(
                      spacing: 8,
                      children: [
                        if ((_numCameras ?? 0) > 1)
                          ModernButton.svg(
                            size: 36,
                            iconSize: 24,
                            svgPath: "assets/new-ui/camera_flip.svg",
                            onPressed: () {
                              controller.switchCamera();
                              setState(() {
                                _frontFlashMode = false;
                              });
                            },
                            iconColor: buttonIconColor,
                            backgroundColor: buttonColor,
                          ),
                        ModernButton(
                          size: 36,
                          iconSize: 24,
                          icon: Icon(
                            (controller.value.torchState == TorchState.on || _frontFlashMode)
                                ? Icons.flash_off_outlined
                                : Icons.flash_on,
                          ),
                          onPressed: () {
                            if (controller.value.cameraDirection == CameraFacing.front) {
                              setState(() {
                                _frontFlashMode = !_frontFlashMode;
                              });
                            } else {
                              controller.toggleTorch();
                            }
                          },
                          iconColor: buttonIconColor,
                          backgroundColor: buttonColor,
                        ),
                      ],
                    ),
                  ),
                  leadingWidget: Row(
                    textBaseline: TextBaseline.ideographic,
                    spacing: 24,
                    children: [
                      ModernButton(
                        size: 36,
                        iconSize: 18,
                        icon: Icon(Icons.arrow_back_ios_new),
                        onPressed: () {
                          if (_textInputMode) {
                            setState(() {
                              _textInputMode = false;
                            });
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        iconColor: buttonIconColor,
                        backgroundColor: buttonColor,
                      ),
                      Text(
                        S.of(context).scan,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: buttonIconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Input de texto manual.
          Positioned(
            bottom: 18 +
                max(
                  MediaQuery.of(context).viewInsets.bottom,
                  MediaQuery.of(context).viewPadding.bottom,
                ),
            left: 16,
            right: 16,
            child: RepaintBoundary(
              child: AnimatedOpacity(
                opacity: _textInputMode ? 1 : 0,
                duration: textModeSwitchDuration,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: TextField(
                          enabled: _textInputMode,
                          controller: textController,
                          focusNode: textFocusNode,
                          onSubmitted: (val) {
                            if (val.isNotEmpty) {
                              // Validar input manual también.
                              final result =
                                  validateQrContent(val, currentSymbol: widget.currentSymbol);
                              if (result.isValid) {
                                Navigator.of(context).pop(result.address ?? val);
                              } else {
                                _showValidationAlert(result);
                              }
                            } else {
                              setState(() {
                                _textInputMode = false;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: S.of(context).enter_code,
                          ),
                        ),
                      ),
                      FloatingIconButton(
                        iconPath: "assets/new-ui/paste.svg",
                        onPressed: () async {
                          final data = await Clipboard.getData("text/plain");
                          if (data?.text != null) {
                            textController.text = data!.text!;
                          }
                        },
                      ),
                      const SizedBox(width: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Botones inferiores (input manual + ayuda).
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: AnimatedOpacity(
                duration: textModeSwitchDuration,
                opacity: _textInputMode ? 0 : 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    if (widget.showManualInput)
                      ScanPageButton(
                        onTap: () {
                          setState(() {
                            _textInputMode = true;
                          });
                          Future.delayed(textModeSwitchDuration)
                              .then((_) => textFocusNode.requestFocus());
                        },
                        icon: Icons.edit_outlined,
                        label: S.of(context).manual_input,
                        buttonColor: buttonColor,
                        buttonIconColor: buttonIconColor,
                      ),
                    if (widget.showHelp)
                      ScanPageButton(
                        onTap: () async {
                          if (_textInputMode) return;
                          try {
                            controller.stop();
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              builder: (context) => ScanPageNetworkList(),
                            );
                          } finally {
                            controller.start();
                          }
                        },
                        icon: Icons.question_mark,
                        buttonColor: buttonColor,
                        buttonIconColor: buttonIconColor,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Indicador de UR scanning.
          AnimatedOpacity(
            duration: Duration(milliseconds: 500),
            opacity: isScanningURQR ? 1 : 0,
            child: Center(
              child: SegmentedCircularProgress(
                progress: URQrProgress(
                  expectedPartCount: decoder.expectedPartCount() ?? 0,
                  processedPartsCount: decoder.processedPartsCount(),
                  receivedPartIndexes: decoder.receivedPartIndexes().toList(),
                  percentage: decoder.estimatedPercentComplete(),
                ),
                size: cutoutSize + 20,
                activeColor: brandPrimary,
                inactiveColor: Colors.white.withAlpha(102),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: isScanningURQR ? 1 : 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${decoder.processedPartsCount()}",
                      style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.w500,
                        color: brandPrimary,
                      ),
                    ),
                    Text(
                      "/",
                      style: TextStyle(
                        fontSize: 45,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      "${decoder.expectedPartCount()}",
                      style: TextStyle(
                        fontSize: 45,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanPageButton extends StatelessWidget {
  const ScanPageButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.label,
    required this.buttonColor,
    required this.buttonIconColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String? label;
  final Color buttonColor;
  final Color buttonIconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(99999),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            left: label == null ? 10 : 16,
            right: label == null ? 10 : 20,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Icon(icon, size: 28, color: buttonIconColor),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: buttonIconColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoleClipper extends CustomClipper<Path> {
  final double width;
  final double height;
  final double radius;

  HoleClipper({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final fullScreenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: width,
            height: height,
          ),
          Radius.circular(radius),
        ),
      );
    return Path.combine(PathOperation.difference, fullScreenPath, cutoutPath);
  }

  @override
  bool shouldReclip(covariant HoleClipper oldClipper) {
    return oldClipper.width != width || oldClipper.height != height || oldClipper.radius != radius;
  }
}

class SegmentedCircularProgress extends StatelessWidget {
  final URQrProgress progress;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const SegmentedCircularProgress({
    Key? key,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SegmentedCirclePainter(
        progress: progress,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}

class _SegmentedCirclePainter extends CustomPainter {
  final URQrProgress progress;
  static const double strokeWidth = 10;
  static const double gapAngle = 0.08;
  final Color activeColor;
  final Color inactiveColor;

  _SegmentedCirclePainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final totalSegments = progress.expectedPartCount;
    final sweepAngle = (2 * pi - (gapAngle * totalSegments)) / totalSegments;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    double startAngle = -pi / 2 + (gapAngle / 2);
    for (int i = 0; i < totalSegments; i++) {
      bool isHighlighted = progress.receivedPartIndexes.contains(i);
      paint.color = isHighlighted ? activeColor : inactiveColor;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedCirclePainter oldDelegate) {
    return !oldDelegate.progress.equals(progress) ||
        oldDelegate.progress.expectedPartCount != progress.expectedPartCount;
  }
}
