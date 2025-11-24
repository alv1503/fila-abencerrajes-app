// lib/pages/admin/create_user_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _dniController = TextEditingController(); // DNI amb lletra
  final _moteController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();

  DateTime? _birthDate;
  bool _isLoading = false;

  // --- LÒGICA SENIOR (1 SEPTEMBRE) ---
  bool _calculateIsSenior(DateTime birthDate) {
    final now = DateTime.now();
    // Any "fester/lectiu" actual.
    // Si estem en 2024, volem saber si compleix 21 abans de l'1 de setembre de 2024.

    // Data límit: 1 de setembre de l'any actual
    final limitDate = DateTime(now.year, 9, 1);

    // Calculem l'edat que tindrà en eixa data límit
    int ageAtLimit = limitDate.year - birthDate.year;
    if (limitDate.month < birthDate.month ||
        (limitDate.month == birthDate.month && limitDate.day < birthDate.day)) {
      ageAtLimit--;
    }

    // Si per a l'1 de setembre ja té 21 anys (o més), és Senior.
    return ageAtLimit >= 21;
  }

  // --- NETEJA DE CONTRASENYA (DNI SENSE LLETRA) ---
  String _cleanDniForPassword(String dni) {
    // Eliminem qualsevol caràcter que no siga un número
    return dni.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la data de naixement.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    FirebaseApp? secondaryApp;
    try {
      // Inicialitzem una app secundària per a no tancar la sessió de l'admin actual
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 1. La contrasenya és només els números del DNI
      String password = _cleanDniForPassword(_dniController.text.trim());

      if (password.length < 6) {
        throw Exception(
          "El DNI ha de tindre almenys 6 números per a la contrasenya.",
        );
      }

      // 2. Creem l'usuari a Auth
      UserCredential cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: password,
      );

      // 3. Calculem rol inicial
      bool isSenior = _calculateIsSenior(_birthDate!);

      // 4. Guardem a Firestore
      await FirebaseFirestore.instance
          .collection('membres')
          .doc(cred.user!.uid)
          .set({
            'nom': _nameController.text.trim(),
            'cognoms': _surnameController.text.trim(),
            'mote': _moteController.text.trim(),
            'email': _emailController.text.trim(),
            'dni': _dniController.text
                .trim()
                .toUpperCase(), // Guardem el DNI complet
            'telefon': '',
            'adreca': '',
            'dataNaixement': Timestamp.fromDate(_birthDate!),
            'tipusQuota': 'normal',
            'enExcedencia': false,
            'isAdmin': false,
            'linkedChildrenUids': [],
            'descripcio': '',
            'fotoUrl': null,
            // Guardem el camp calculat, tot i que el model també ho pot calcular dinàmicament
            // És útil tindre-ho en BD per a consultes ràpides
            'isSenior': isSenior,
          });

      await secondaryAuth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuari creat correctament!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nou Usuari')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Dades d\'Accés',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Camp obligatori' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _dniController,
                    textCapitalization:
                        TextCapitalization.characters, // DNI en majúscules
                    decoration: const InputDecoration(
                      labelText: 'DNI complet',
                      hintText: '12345678X',
                      helperText: 'La contrasenya seran només els números.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Camp obligatori' : null,
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Dades Personals',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _moteController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Mote (Nom públic)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Camp obligatori' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Nom Real',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Camp obligatori' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _surnameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Cognoms',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Camp obligatori' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text(
                      _birthDate == null
                          ? 'Seleccionar Data de Naixement'
                          : 'Data: ${DateFormat('dd/MM/yyyy').format(_birthDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    onTap: () => _selectDate(context),
                  ),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _createUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Crear Usuari'),
                  ),
                ],
              ),
            ),
    );
  }
}
