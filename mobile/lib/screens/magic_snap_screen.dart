import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/agri_pulse_models.dart';

class MagicSnapScreen extends ConsumerStatefulWidget {
  const MagicSnapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MagicSnapScreen> createState() => _MagicSnapScreenState();
}

class _MagicSnapScreenState extends ConsumerState<MagicSnapScreen>
    with SingleTickerProviderStateMixin {
  bool isDetecting = false;
  bool boundaryDetected = false;
  late AnimationController _pulseController;
  MagicSnapResult? detectionResult;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.magicSnap),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (!boundaryDetected || detectionResult == null)
            _buildCameraView(context, l10n)
          else
            _buildBoundaryConfirmation(context, l10n),

          // Back floating button (when showing confirmation)
          if (boundaryDetected && detectionResult != null)
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    boundaryDetected = false;
                    detectionResult = null;
                  });
                },
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: Icon(Icons.arrow_back),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Camera placeholder
          Container(
            color: Colors.grey[900],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Camera View',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Crosshair overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Crosshair circle
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),

                    // Animated pulse (when detecting)
                    if (isDetecting)
                      ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.2).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                              width: 3,
                            ),
                          ),
                        ),
                      ),

                    // Crosshair lines
                    Column(
                      children: [
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.white,
                        ),
                        SizedBox(height: 60),
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          color: Colors.white,
                        ),
                        SizedBox(width: 60),
                        Container(
                          width: 40,
                          height: 2,
                          color: Colors.white,
                        ),
                      ],
                    ),

                    // Center dot
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Instructions panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 ${l10n.centerCrosshair}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _startDetection();
                      },
                      icon: Icon(Icons.camera),
                      label: Text(isDetecting ? 'Detecting...' : 'Snap & Detect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildBoundaryConfirmation(
      BuildContext context, AppLocalizations l10n) {
    if (detectionResult == null) return SizedBox();

    return Stack(
      children: [
        // Map background with polygon overlay
        Container(
          color: Color(0xFFE8F5E9),
          child: Stack(
            children: [
              // Grid pattern
              GridView.count(
                crossAxisCount: 10,
                children: List.generate(100, (index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green[100]!,
                        width: 0.5,
                      ),
                    ),
                  );
                }),
              ),

              // Polygon visualization
              Center(
                child: CustomPaint(
                  size: Size(300, 300),
                  painter: PolygonPainter(detectionResult!.polygonCoordinates),
                ),
              ),

              // Success overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom confirmation panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.green[600],
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.boundaryDetected,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${detectionResult!.acreage.toStringAsFixed(2)} acres detected',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Validation info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Validation Results',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              detectionResult!.validationMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            boundaryDetected = false;
                            detectionResult = null;
                          });
                        },
                        child: Text(l10n.retake),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _confirmBoundary();
                        },
                        icon: Icon(Icons.check_circle),
                        label: Text(l10n.confirmBoundary),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _startDetection() {
    setState(() {
      isDetecting = true;
    });

    // Simulate SAM 3 detection
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isDetecting = false;
        boundaryDetected = true;
        detectionResult = MagicSnapResult(
          polygonCoordinates: [
            [28.6139, 77.2090],
            [28.6150, 77.2100],
            [28.6145, 77.2110],
            [28.6130, 77.2105],
          ],
          acreage: 12.5,
          isValidated: true,
          validationMessage:
              '✓ Field size within limits (12.5 acres, <20 acre max)\n✓ Location confirmed within 2km of GPS\n✓ No conflicting claims detected',
        );
      });
    });
  }

  void _confirmBoundary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✓ Land Claim Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your field boundary has been successfully recorded:'),
            SizedBox(height: 16),
            _buildDetailRow('Acreage', '${detectionResult!.acreage} acres'),
            _buildDetailRow(
              'Coordinates',
              '${detectionResult!.polygonCoordinates.length} points',
            ),
            _buildDetailRow('Status', 'Active'),
            SizedBox(height: 16),
            Text(
              'Next: Set up your crop profile and enable notifications.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Back to Map'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Set Up Crop'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<List<double>> coordinates;

  PolygonPainter(this.coordinates);

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Scale coordinates to canvas size
    double minLat = coordinates.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
    double maxLat = coordinates.map((c) => c[0]).reduce((a, b) => a > b ? a : b);
    double minLng = coordinates.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
    double maxLng = coordinates.map((c) => c[1]).reduce((a, b) => a > b ? a : b);

    double latRange = maxLat - minLat;
    double lngRange = maxLng - minLng;

    for (int i = 0; i < coordinates.length; i++) {
      double x =
          ((coordinates[i][1] - minLng) / lngRange) * size.width * 0.8 +
              (size.width * 0.1);
      double y =
          ((coordinates[i][0] - minLat) / latRange) * size.height * 0.8 +
              (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    for (var coord in coordinates) {
      double x =
          ((coord[1] - minLng) / lngRange) * size.width * 0.8 +
              (size.width * 0.1);
      double y =
          ((coord[0] - minLat) / latRange) * size.height * 0.8 +
              (size.height * 0.1);

      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = Colors.green[600]!
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(PolygonPainter oldDelegate) => false;
}
