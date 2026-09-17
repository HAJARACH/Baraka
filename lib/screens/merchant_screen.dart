import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'qr_scanner_screen.dart';

class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _verifiedDeal;
  bool _isAlreadyRedeemed = false;

  Future<void> _verifyPass([String? codeParam]) async {
    final code = (codeParam ?? _codeController.text).trim();
    if (code.isEmpty) return;
    if (codeParam != null) {
      _codeController.text = codeParam;
    }

    setState(() {
      _isSearching = true;
      _verifiedDeal = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('bookings')
          .select('id, pass_code, status, deals(*)')
          .eq('pass_code', code)
          .maybeSingle();

      setState(() {
        _isSearching = false;
        if (data != null) {
          final dealData = data['deals'] as Map<String, dynamic>;
          _isAlreadyRedeemed = data['status'] == 'consomme';
          _verifiedDeal = {
            'bookingId': data['id'],
            'title': dealData['title'],
            'business': dealData['business_name'],
            'amountToPay': dealData['discounted_price'],
            'passCode': data['pass_code'],
            'status': _isAlreadyRedeemed ? 'DÉJÀ ENCAISSÉ' : 'VALIDE',
          };
        } else {
          _verifiedDeal = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Code introuvable.")),
          );
        }
      });
    } catch (e) {
      debugPrint('Erreur vérification : $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      final code = result['code']?.toString().trim() ?? '';
      if (code.isNotEmpty) {
        _codeController.text = code;
        await _verifyPass(code);
      }
    }
  }

  Future<void> _redeemPass() async {
    if (_verifiedDeal == null) return;
    final bookingId = _verifiedDeal!['bookingId'];

    final supabase = Supabase.instance.client;
    await supabase
        .from('bookings')
        .update({'status': 'consomme'})
        .eq('id', bookingId);

    setState(() {
      _isAlreadyRedeemed = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pass validé et marqué comme consommé en base !"),
        backgroundColor: BarakaColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarakaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: BarakaColors.textPrimary,
        title: const Text(
          "Espace Commerçant",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de saisie / scan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Valider un Pass Client",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scannez le QR Code ou entrez le code à 6 chiffres affiché sur le téléphone du client.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openQrScanner,
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text(
                        "Scanner avec l'appareil photo",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BarakaColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "OU SAISIR LE PIN",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Ex : 492810",
                            prefixIcon: const Icon(Icons.pin, color: BarakaColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: BarakaColors.primary, width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _verifyPass(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _verifyPass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BarakaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Vérifier", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Résultat de la vérification
            if (_verifiedDeal != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAlreadyRedeemed ? Colors.grey : BarakaColors.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isAlreadyRedeemed ? Colors.grey.shade200 : BarakaColors.sage,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isAlreadyRedeemed ? "DÉJÀ ENCAISSÉ" : "PASS VALIDE",
                            style: TextStyle(
                              color: _isAlreadyRedeemed ? Colors.grey.shade700 : BarakaColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          "Code : ${_verifiedDeal!['passCode']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _verifiedDeal!['title'],
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Établissement : ${_verifiedDeal!['business']}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Montant à encaisser :",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "${_verifiedDeal!['amountToPay']} MAD",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: BarakaColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAlreadyRedeemed ? null : _redeemPass,
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          _isAlreadyRedeemed ? "Offre consommée" : "Confirmer l'encaissement",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BarakaColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
