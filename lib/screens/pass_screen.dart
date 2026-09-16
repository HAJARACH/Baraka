import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/deal.dart';
import '../theme/app_theme.dart';

class PassScreen extends StatelessWidget {
  final String dealId;
  final String businessName;
  final String title;
  final double discountedPrice;
  final String location;
  final String passCode;
  final DateTime? expiresAt;

  PassScreen({
    super.key,
    required Deal deal,
    required this.passCode,
  })  : dealId = deal.id,
        businessName = deal.businessName,
        title = deal.title,
        discountedPrice = deal.discountedPrice,
        location = deal.location,
        expiresAt = deal.expiresAt;

  const PassScreen.fromDetails({
    super.key,
    required this.dealId,
    required this.businessName,
    required this.title,
    required this.discountedPrice,
    required this.location,
    required this.passCode,
    this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    // Données encodées dans le QR Code
    final qrPayload = jsonEncode({
      'deal_id': dealId,
      'code': passCode,
    });

    String remainingText = "";
    if (expiresAt != null) {
      final now = DateTime.now();
      if (expiresAt!.isAfter(now)) {
        final diff = expiresAt!.difference(now);
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        remainingText = h > 0 ? "Valable encore ${h}h ${m}m" : "Valable encore ${m}m";
      } else {
        remainingText = "Offre expirée";
      }
    }

    return Scaffold(
      backgroundColor: BarakaColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "Votre Pass Baraka",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Établissement
                    Text(
                      businessName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 15, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 190.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: BarakaColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "Ou présentez ce code à 6 chiffres :",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Code PIN à 6 chiffres avec bouton copier
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: passCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Code copié dans le presse-papiers !"),
                            duration: Duration(seconds: 2),
                            backgroundColor: BarakaColors.primary,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: BarakaColors.sageLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: BarakaColors.sage),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              passCode,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 5,
                                color: BarakaColors.terracotta,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy,
                                size: 18, color: BarakaColors.terracotta),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("À régler sur place :",
                            style: TextStyle(
                                fontSize: 14, color: Colors.black54)),
                        Text(
                          "${discountedPrice.toStringAsFixed(0)} MAD",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: BarakaColors.primary,
                          ),
                        ),
                      ],
                    ),

                    if (remainingText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 16, color: Colors.orange.shade800),
                            const SizedBox(width: 6),
                            Text(
                              remainingText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bannière de réassurance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Pass sauvegardé dans l'onglet 'Mes Pass'.",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
