import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _verifyPass() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

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
      setState(() => _isSearching = false);
      debugPrint('Erreur vérification : $e');
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
        backgroundColor: Color(0xFF00897B),
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
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Espace Commerçant",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Ex : 492810",
                            prefixIcon: const Icon(Icons.pin, color: Color(0xFF00897B)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _verifyPass(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _verifyPass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
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
                    color: _isAlreadyRedeemed ? Colors.grey : const Color(0xFF00897B),
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
                            color: _isAlreadyRedeemed ? Colors.grey.shade200 : const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isAlreadyRedeemed ? "DÉJÀ ENCAISSÉ" : "PASS VALIDE",
                            style: TextStyle(
                              color: _isAlreadyRedeemed ? Colors.grey.shade700 : const Color(0xFF00897B),
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
                            color: Color(0xFF00897B),
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
                          backgroundColor: const Color(0xFF00897B),
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
