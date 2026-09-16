import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class MerchantDashboardScreen extends StatefulWidget {
  final VoidCallback? onOfferPublished;
  const MerchantDashboardScreen({super.key, this.onOfferPublished});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final supabase = Supabase.instance.client;
  final _codeController = TextEditingController();

  // État de validation de pass
  bool _isValidating = false;
  Map<String, dynamic>? _foundBooking;

  // Formulaire d'ajout
  final _titleController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _stockController = TextEditingController(text: "5");
  final _locationController = TextEditingController(text: "Guéliz, Marrakech");
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isPublishing = false;

  static const Map<String, String> _categoryImages = {
    'Food': 'https://images.unsplash.com/photo-1541544741938-0af808871cc0',
    'Bien-être': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef',
    'Activités': 'https://images.unsplash.com/photo-1533105079780-92b9be482077',
    'Shopping': 'https://images.unsplash.com/photo-1472851294608-062f824d29cc',
  };

  String? _businessName;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadMerchantProfile();
  }

  Future<void> _loadMerchantProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final profile = await supabase
            .from('profiles')
            .select('business_name')
            .eq('id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _businessName = profile?['business_name'] ??
                user.userMetadata?['business_name'] ??
                'Établissement Partenaire';
            _loadingProfile = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingProfile = false);
      }
    } else {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  // Recherche du pass par code
  Future<void> _searchPass() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _foundBooking = null;
    });

    try {
      final response = await supabase
          .from('bookings')
          .select('id, pass_code, status, deals(id, title, business_name, discounted_price, original_price)')
          .eq('pass_code', code)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        _showMessage("Code introuvable. Veuillez vérifier le code client.", Colors.redAccent);
      } else {
        setState(() {
          _foundBooking = response;
        });
      }
    } catch (e) {
      _showMessage("Erreur de recherche : $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // Confirmation de l'encaissement et marquage du pass comme utilisé
  Future<void> _confirmRedeemPass() async {
    if (_foundBooking == null) return;
    final bookingId = _foundBooking!['id'];

    try {
      await supabase
          .from('bookings')
          .update({'status': 'utilise'})
          .eq('id', bookingId);

      if (!mounted) return;

      final dealData = _foundBooking!['deals'] as Map<String, dynamic>?;
      final dealTitle = dealData?['title'] ?? 'Offre flash';

      setState(() {
        _foundBooking!['status'] = 'utilise';
      });

      _showMessage("Pass validé et encaissé avec succès pour : $dealTitle !", BarakaColors.primary);
      _codeController.clear();
    } catch (e) {
      _showMessage("Erreur de validation : $e", BarakaColors.terracotta);
    }
  }

  // Publication d'une nouvelle offre flash
  Future<void> _publishDeal() async {
    final title = _titleController.text.trim();
    final orig = double.tryParse(_originalPriceController.text.trim());
    final disc = double.tryParse(_discountedPriceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim()) ?? 5;
    final location = _locationController.text.trim();
    final img = _imageUrlController.text.trim();

    if (title.isEmpty || orig == null || disc == null) {
      _showMessage("Veuillez renseigner le titre et les prix.", Colors.orange);
      return;
    }

    setState(() => _isPublishing = true);
    final user = supabase.auth.currentUser;

    try {
      final discountPct = (((orig - disc) / orig) * 100).round();
      final defaultImg = _categoryImages[_selectedCategory] ??
          'https://images.unsplash.com/photo-1541544741938-0af808871cc0';

      await supabase.from('deals').insert({
        'title': title,
        'business_name': _businessName ?? 'Établissement Partenaire',
        'location': location.isNotEmpty ? location : 'Marrakech',
        'latitude': 31.6295,
        'longitude': -7.9811,
        'original_price': orig,
        'discounted_price': disc,
        'discount_percentage': discountPct,
        'image_url': img.isNotEmpty ? img : defaultImg,
        'category': _selectedCategory,
        'remaining_count': stock,
        'expires_at':
            DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
        if (user != null) 'merchant_id': user.id,
      });

      if (!mounted) return;

      _titleController.clear();
      _originalPriceController.clear();
      _discountedPriceController.clear();
      _stockController.text = "5";
      _imageUrlController.clear();

      _showMessage("Offre flash publiée avec succès ! (Valable 4h)", BarakaColors.primary);
      if (widget.onOfferPublished != null) widget.onOfferPublished!();
      setState(() {});
    } catch (e) {
      _showMessage("Erreur lors de la publication : $e", BarakaColors.terracotta);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // Chargement des offres du commerçant
  Future<List<Map<String, dynamic>>> _fetchMyDeals() async {
    final bName = _businessName;
    try {
      var query = supabase.from('deals').select();
      if (bName != null && bName.isNotEmpty && bName != 'Établissement Partenaire') {
        query = query.eq('business_name', bName);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      // Si la table n'a pas created_at ou filtre échoue, fallback sur tous les deals récents
      final data = await supabase.from('deals').select().limit(20);
      return List<Map<String, dynamic>>.from(data);
    }
  }

  Future<void> _deleteMyDeal(String dealId) async {
    try {
      await supabase.from('deals').delete().eq('id', dealId);
      _showMessage("Offre supprimée avec succès.", BarakaColors.primary);
      setState(() {});
    } catch (e) {
      _showMessage("Erreur : $e", BarakaColors.terracotta);
    }
  }

  void _showMessage(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bName = _businessName ?? "Mon Établissement";

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: BarakaColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: BarakaColors.sage,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront, color: BarakaColors.primary),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Espace Professionnel",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Text(
                    _loadingProfile ? "Chargement..." : bName,
                    style: const TextStyle(fontSize: 11, color: BarakaColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: BarakaColors.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Rafraîchir",
              onPressed: () => setState(() {}),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: BarakaColors.terracotta),
              tooltip: "Déconnexion",
              onPressed: () => supabase.auth.signOut(),
            ),
          ],
          bottom: const TabBar(
            labelColor: BarakaColors.primary,
            indicatorColor: BarakaColors.primary,
            indicatorWeight: 3,
            isScrollable: false,
            tabs: [
              Tab(
                icon: Icon(Icons.qr_code_scanner),
                text: "Valider pass",
              ),
              Tab(
                icon: Icon(Icons.add_circle_outline),
                text: "Publier deal",
              ),
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: "Mes offres",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildValidatorTab(),
            _buildPublishTab(),
            _buildMyDealsTab(),
          ],
        ),
      ),
    );
  }

  // Onglet 1 : Validation de pass
  Widget _buildValidatorTab() {
    final dealData = _foundBooking?['deals'] as Map<String, dynamic>?;
    final isAlreadyUsed = _foundBooking?['status'] == 'utilise' ||
        _foundBooking?['status'] == 'consomme';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carte de saisie du PIN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: BarakaColors.primary),
                    SizedBox(width: 8),
                    Text(
                      "Validation du Pass Client",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Saisissez le code à 6 chiffres affiché sur le téléphone du client pour vérifier et encaisser.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "123456",
                          prefixIcon: const Icon(Icons.pin,
                              color: BarakaColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: BarakaColors.primary, width: 2),
                          ),
                        ),
                        onSubmitted: (_) => _searchPass(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isValidating ? null : _searchPass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BarakaColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isValidating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Vérifier",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Résultat du pass
          if (_foundBooking != null && dealData != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAlreadyUsed ? BarakaColors.terracotta : BarakaColors.primary,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAlreadyUsed
                              ? BarakaColors.terracottaLight
                              : BarakaColors.sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAlreadyUsed ? "PASS DÉJÀ UTILISÉ" : "PASS VALIDE",
                          style: TextStyle(
                            color: isAlreadyUsed
                                ? BarakaColors.terracotta
                                : BarakaColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        "Code : ${_foundBooking!['pass_code']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    dealData['title'] ?? 'Offre Baraka',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Établissement : ${dealData['business_name'] ?? 'Partenaire'}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Montant à encaisser sur place :",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "${dealData['discounted_price']} MAD",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: BarakaColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isAlreadyUsed ? null : _confirmRedeemPass,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        isAlreadyUsed
                            ? "Pass déjà encaissé"
                            : "Confirmer l'encaissement",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BarakaColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Onglet 2 : Publication de deal
  Widget _buildPublishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BarakaColors.sage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: BarakaColors.primary, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Votre offre sera immédiatement visible par les clients de Marrakech pendant 4 heures.",
                    style: TextStyle(
                        fontSize: 13,
                        color: BarakaColors.primaryDark,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Titre de l'offre flash",
              hintText: "Ex : Brunch 2 personnes ou Tajine + Thé",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _originalPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Prix normal (MAD)",
                    hintText: "Ex : 150",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discountedPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Prix flash (MAD)",
                    hintText: "Ex : 75",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Portions / Places",
                    hintText: "Ex : 5",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: "Quartier",
                    hintText: "Guéliz, Médina...",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: "Catégorie",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ['Food', 'Bien-être', 'Activités', 'Shopping']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: "URL de l'image (optionnel)",
              hintText: "https://... (laisser vide pour image par défaut)",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishDeal,
              icon: const Icon(Icons.flash_on),
              label: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Publier l'offre flash (4h)",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }

  // Onglet 3 : Mes offres en cours
  Widget _buildMyDealsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMyDeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final deals = snapshot.data ?? [];
        if (deals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  "Aucune offre active pour le moment",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Publiez votre premier bon plan dans l'onglet voisin !",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deals.length,
            itemBuilder: (context, index) {
              final d = deals[index];
              final id = d['id']?.toString() ?? '';
              final title = d['title'] ?? 'Offre sans nom';
              final price = d['discounted_price'] ?? 0;
              final stock = d['remaining_count'] ?? 0;

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      d['image_url'] ??
                          'https://images.unsplash.com/photo-1541544741938-0af808871cc0',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$price MAD • Restant : $stock"),
                  trailing: IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteMyDeal(id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
