import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);
    final rawValue = barcode.rawValue!;

    try {
      final data = jsonDecode(rawValue);
      if (mounted) {
        Navigator.pop(context, {
          'deal_id': data['deal_id'],
          'code': data['code']?.toString() ?? '',
        });
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context, {
          'code': rawValue,
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Scanner le Pass Client",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            tooltip: "Flash",
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            tooltip: "Changer de caméra",
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          size: 64, color: Colors.white70),
                      const SizedBox(height: 16),
                      Text(
                        "Accès à l'appareil photo requis : ${error.errorDetails?.message ?? error.errorCode.name}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Retour à la saisie manuelle"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BarakaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Cadre de visée central
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: BarakaColors.primary, width: 3.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: BarakaColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Instruction sous le cadre
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Placez le QR Code Baraka dans le cadre",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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