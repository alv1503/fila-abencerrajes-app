// lib/pages/forms/edit_profile_page.dart
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Un formulari [StatefulWidget] per a editar el perfil de l'usuari loguejat.
///
/// Rep el [MemberModel] actual de l'usuari per a omplir
/// inicialment els camps del formulari.
class EditProfilePage extends StatefulWidget {
  final MemberModel currentMember;

  const EditProfilePage({super.key, required this.currentMember});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Obtenim l'ID de l'usuari des d'Auth
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Controladors per als camps editables
  late TextEditingController _moteController;
  late TextEditingController _telefonController;
  late TextEditingController _adrecaController;
  late TextEditingController _descripcioController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicialitzem els controladors amb les dades actuals
    // que hem rebut del widget [currentMember].
    _moteController = TextEditingController(text: widget.currentMember.mote);
    _telefonController = TextEditingController(
      text: widget.currentMember.telefon,
    );
    _adrecaController = TextEditingController(
      text: widget.currentMember.adreca,
    );
    _descripcioController = TextEditingController(
      text: widget.currentMember.descripcio ?? '',
    );
  }

  @override
  void dispose() {
    // Alliberem els controladors
    _moteController.dispose();
    _telefonController.dispose();
    _adrecaController.dispose();
    _descripcioController.dispose();
    super.dispose();
  }

  /// Valida el formulari i actualitza les dades del perfil a Firestore.
  Future<void> _saveProfile() async {
    // 1. Validar el formulari
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Activa l'estat de càrrega
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Crida al servei de Firestore per a actualitzar les dades
      await _firestoreService.updateMemberProfile(
        uid: _userId,
        mote: _moteController.text.trim(),
        telefon: _telefonController.text.trim(),
        adreca: _adrecaController.text.trim(),
        descripcio: _descripcioController.text.trim(),
      );

      // 4. Si té èxit, tanca el formulari i mostra missatge
      if (mounted) {
        Navigator.pop(context); // Torna a la pàgina de Perfil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualitzat amb èxit!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 5. Si hi ha un error, mostra'l
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en actualitzar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. En qualsevol cas, desactiva l'estat de càrrega
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Funció de validació simple.
  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aquest camp no pot estar buit';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Camp de Mote ---
                  TextFormField(
                    controller: _moteController,
                    decoration: const InputDecoration(
                      labelText: 'Mote',
                      icon: Icon(Icons.person_pin_rounded),
                    ),
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),

                  // --- Camp de Telèfon ---
                  TextFormField(
                    controller: _telefonController,
                    decoration: const InputDecoration(
                      labelText: 'Telèfon',
                      icon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),

                  // --- Camp d'Adreça ---
                  TextFormField(
                    controller: _adrecaController,
                    decoration: const InputDecoration(
                      labelText: 'Adreça',
                      icon: Icon(Icons.home),
                    ),
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),

                  // --- Camp de Descripció ---
                  TextFormField(
                    controller: _descripcioController,
                    decoration: const InputDecoration(
                      labelText: 'Descripció',
                      hintText: 'Una breu descripció sobre tu...',
                      icon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    // Aquest camp pot estar buit, per tant, no té validador.
                  ),
                  const SizedBox(height: 32),

                  // --- Botó de Guardar ---
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text(
                      'Guardar Canvis',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
