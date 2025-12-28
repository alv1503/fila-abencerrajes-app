// lib/auth/setup_profile_page.dart
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/pages/tabs/home_feed_page.dart'; // O la ruta a tu Home
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _fs = FirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // Controladores
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _moteController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _birthDate;
  bool _isLoading = false;

  // Guardar dades
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La data de naixement és obligatòria")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Preparem les dades per a guardar
      final data = {
        'dni': _dniController.text.toUpperCase().trim(),
        'telefon': _phoneController.text.trim(),
        'adreca': _addressController.text.trim(),
        'mote': _moteController.text.trim(),
        'descripcio': _descController.text.trim(),
        'dataNaixement': Timestamp.fromDate(_birthDate!),
        // IMPORTANT: Això és el que desbloqueja l'app
        'isSetupComplete': true,
      };

      await _fs.completeUserProfile(_uid, data);

      if (mounted) {
        // Naveguem al Home i eliminem tot l'historial anterior
        // Assegura't que 'MainScaffold' és el nom de la teua pantalla principal
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Selector de Data
  void _pickDate() {
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1920, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        setState(() => _birthDate = date);
      },
      currentTime: DateTime(2000, 1, 1),
      locale: LocaleType.es, // O 'es' si prefereixes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completa el teu Perfil"),
        automaticallyImplyLeading: false, // No deixem tornar arrere
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Benvingut a la Filà!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Abans de començar, necessitem que emplenes les teues dades personals. Açò només ho hauràs de fer una vegada.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle("Dades Obligatòries"),

              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(
                  labelText: 'DNI / NIF',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => v!.isEmpty ? 'El DNI és obligatori' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telèfon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'El telèfon és obligatori' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adreça Completa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'L\'adreça és obligatòria' : null,
              ),
              const SizedBox(height: 15),

              // Selector de Data personalitzat
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de Naixement',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Selecciona la data'
                        : DateFormat('dd/MM/yyyy').format(_birthDate!),
                    style: TextStyle(
                      color: _birthDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              _buildSectionTitle("Opcional (Pots editar-ho després)"),

              TextFormField(
                controller: _moteController,
                decoration: const InputDecoration(
                  labelText: 'Mote / Àlies',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.face),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripció curta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "GUARDAR I ENTRAR",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
