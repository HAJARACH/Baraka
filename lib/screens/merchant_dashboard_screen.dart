import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final supabase = Supabase.instance.client;
  final _codeController = TextEditingController();

  // Formulaire d'ajout
  final _titleController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isPublishing = false;

  Future<void> _validatePass() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    try {
      final response = await supabase
          .from('bookings')
          .select('id, status, deals(title, business_name)')
          .eq('pass_code', code)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        _showMessage("Code introuvable.", Colors.redAccent);
        return;
      }

      if (response['status'] == 'utilise') {
        _showMessage("Ce pass a déjà été utilisé !", Colors.orange);
        return;
      }

      // Marquer comme utilisé
      await supabase
          .from('bookings')
          .update({'status': 'utilise'}).eq('id', response['id']);

      final dealTitle = response['deals']?['title'] ?? 'Offre Baraka';
      _codeController.clear();
      _showMessage("Pass validé avec succès pour : $dealTitle", const Color(0xFF00897B));
    } catch (e) {
      _showMessage("Erreur : $e", Colors.redAccent);
    }
  }

  Future<void> _publishDeal() async {
    final title = _titleController.text.trim();
    final orig = double.tryParse(_originalPriceController.text.trim());
    final disc = double.tryParse(_discountedPriceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    final image = _imageUrlController.text.trim().isEmpty
        ? 'https://images.unsplash.com/photo-1541544741938-0af808871cc0'
        : _imageUrlController.text.trim();

    if (title.isEmpty || orig == null || disc == null || stock == null) {
      _showMessage("Merci de remplir tous les champs correctement.", Colors.redAccent);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase
          .from('profiles')
          .select('business_name')
          .eq('id', userId)
          .maybeSingle();

      final businessName = profile?['business_name'] ?? 'Établissement Partenaire';

      await supabase.from('deals').insert({
        'business_name': businessName,
        'title': title,
        'original_price': orig,
        'discounted_price': disc,
        'category': _selectedCategory,
        'image_url': image,
        'location': 'Guéliz, Marrakech',
        'remaining_count': stock,
        'expires_at': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
      });

      _titleController.clear();
      _originalPriceController.clear();
      _discountedPriceController.clear();
      _stockController.clear();
      _imageUrlController.clear();

      _showMessage("Offre flash publiée avec succès !", const Color(0xFF00897B));
    } catch (e) {
      _showMessage("Erreur lors de la publication : $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Espace Partenaire",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Déconnexion",
              onPressed: () => supabase.auth.signOut(),
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF00897B),
            indicatorColor: Color(0xFF00897B),
            tabs: [
              Tab(icon: Icon(Icons.check_circle_outline), text: "Valider un pass"),
              Tab(icon: Icon(Icons.add_circle_outline), text: "Publier un deal"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildValidatorTab(),
            _buildPublishTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildValidatorTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Saisissez le code à 6 chiffres présenté par le client :",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: "123456",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _validatePass,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Valider le pass",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Titre de l'offre flash"),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _originalPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Prix normal (MAD)"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discountedPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Prix flash (MAD)"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nombre de places / portions"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: "Catégorie"),
            items: ['Food', 'Bien-être', 'Activités', 'Shopping']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: "URL de l'image (laisser vide par défaut)",
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isPublishing ? null : _publishDeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isPublishing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text("Publier maintenant (Valable 4h)"),
          ),
        ],
      ),
    );
  }
}
