// lib/auth/activate_account_page.dart
import 'package:abenceapp/auth/setup_profile_page.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActivateAccountPage extends StatefulWidget {
  const ActivateAccountPage({super.key});

  @override
  State<ActivateAccountPage> createState() => _ActivateAccountPageState();
}

class _ActivateAccountPageState extends State<ActivateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final FirestoreService _fs = FirestoreService();
  bool _isLoading = false;

  Future<void> _activate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    UserCredential? creds;

    try {
      final email = _emailController.text.trim(); // Quitamos espacios
      final password = _passController.text.trim();

      // --- PASO 1: CREAR EL USUARIO PRIMERO (Para tener permisos) ---
      try {
        creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw "Aquest correu ja està registrat. Torna i inicia sessió.";
        }
        rethrow; // Si es otro error, que salte al catch general
      }

      // --- PASO 2: AHORA QUE ESTAMOS DENTRO, BUSCAMOS LA INVITACIÓN ---
      // Como ya tenemos sesión iniciada, Firestore nos dejará leer (si las reglas son estándar)
      String? tempDocId = await _fs.findPreApprovedUserDocId(email);

      if (tempDocId == null) {
        // 🛑 ALERTA: Se ha colado alguien que NO estaba invitado por el admin.
        // Solución: Borramos el usuario que acabamos de crear y damos error.
        await creds.user?.delete();
        throw "Aquest correu no té invitació de l'administració.";
      }

      // --- PASO 3: SI EXISTE, MIGRAMOS LOS DATOS ---
      // Movemos los datos del documento temporal al UID real del usuario
      await _fs.migrateToRealUser(tempDocId, creds.user!.uid);

      // --- PASO 4: NAVEGAR ---
      if (mounted) {
        // Borramos todo el historial y vamos al Setup
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SetupProfilePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Error d'autenticació";
      if (e.code == 'weak-password')
        msg = "La contrasenya és massa dèbil (mínim 6 caràcters).";
      _showError(msg);
    } catch (e) {
      _showError(e.toString());
      // Si falló algo después de crear el usuario (ej: fallo de base de datos),
      // podríamos querer borrar el usuario para que pueda reintentarlo,
      // pero por seguridad dejaremos que lo gestione el soporte o reintente login.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activar Compte")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.lock_open, size: 60, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Si és la teua primera vegada, introdueix el teu correu i crea una contrasenya nova.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'El teu Correu',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v!.isEmpty || !v.contains('@') ? 'Correu invàlid' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'Nova Contrasenya',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                validator: (v) => v!.length < 6 ? 'Mínim 6 caràcters' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPassController,
                decoration: const InputDecoration(
                  labelText: 'Repeteix Contrasenya',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                validator: (v) => v != _passController.text
                    ? 'Les contrasenyes no coincideixen'
                    : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _activate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("ACTIVAR I ENTRAR"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
