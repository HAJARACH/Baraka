import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  final String targetRole; // 'client' ou 'merchant'
  const AuthScreen({super.key, this.targetRole = 'client'});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      if (_isSignUp) {
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'role': widget.targetRole,
            if (widget.targetRole == 'merchant')
              'business_name': _businessNameController.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Compte créé avec succès !"),
              backgroundColor: Color(0xFF00897B),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMerchant = widget.targetRole == 'merchant';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMerchant ? "Espace Partenaire" : "Connexion Client",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isSignUp
                  ? (isMerchant
                      ? "Rejoignez Baraka comme partenaire"
                      : "Créer un compte pour réserver")
                  : "Bon retour !",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Mot de passe",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_isSignUp && isMerchant) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: "Nom de l'établissement (ex: Riad Jasmine)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isSignUp ? "Créer mon compte" : "Se connecter",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp
                    ? "Déjà inscrit ? Connectez-vous"
                    : "Pas encore de compte ? S'inscrire",
                style: const TextStyle(color: Color(0xFF00897B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
