// lib/pages/forms/edit_profile_page.dart
import 'dart:io'; // Per a mòbil (File)
import 'dart:typed_data'; // Per a Web (Bytes)

import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // NECESSARI PER A PUJAR FOTOS
import 'package:flutter/foundation.dart' show kIsWeb; // Per a saber si és Web
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // NECESSARI PER A OBRIR GALERIA

/// Un formulari [StatefulWidget] per a editar el perfil de l'usuari loguejat.
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

  // --- VARIABLES NOVES PER A LA FOTO ---
  XFile? _imageFile; // L'arxiu seleccionat (comú)
  Uint8List? _webImage; // Els bytes de la imatge (Només per a Web)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicialitzem els controladors amb les dades actuals
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

  // --- 1. FUNCIÓ PER A SELECCIONAR IMATGE (COMPATIBLE WEB I MÒBIL) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Comprimim un poc per a pujar ràpid
        maxWidth: 800, // Limitem l'ample
      );

      if (image != null) {
        if (kIsWeb) {
          // En Web llegim els bytes per a poder mostrar la previsualització
          final f = await image.readAsBytes();
          setState(() {
            _webImage = f;
            _imageFile = image;
          });
        } else {
          // En Android/iOS usem l'arxiu normal
          setState(() {
            _imageFile = image;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obrir galeria: $e')));
    }
  }

  // --- 2. FUNCIÓ PER A GUARDAR I PUJAR A FIREBASE ---
  Future<void> _saveProfile() async {
    // 1. Validar el formulari
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Activa l'estat de càrrega
    setState(() {
      _isLoading = true;
    });

    String? finalFotoUrl = widget.currentMember.fotoUrl;

    try {
      // A) Si hi ha imatge nova seleccionada, la pugem a Storage
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$_userId.jpg'); // Usem l'ID de l'usuari com a nom

        if (kIsWeb) {
          // PUJADA WEB: Usem putData (bytes)
          final bytes = await _imageFile!.readAsBytes();
          await storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          // PUJADA ANDROID: Usem putFile (arxiu)
          await storageRef.putFile(File(_imageFile!.path));
        }

        // Obtenim la URL pública final de la imatge pujada
        finalFotoUrl = await storageRef.getDownloadURL();
      }

      // 3. Crida al servei de Firestore per a actualitzar les dades
      await _firestoreService.updateMemberProfile(
        uid: _userId,
        mote: _moteController.text.trim(),
        telefon: _telefonController.text.trim(),
        adreca: _adrecaController.text.trim(),
        descripcio: _descripcioController.text.trim(),
        fotoUrl:
            finalFotoUrl, // Passem la URL nova (o la vella si no ha canviat)
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

  // --- 3. HELPER PER A SABER QUINA FOTO MOSTRAR ---
  ImageProvider? _getAvatarImage() {
    // 1. Si hem triat foto nova en WEB
    if (kIsWeb && _webImage != null) {
      return MemoryImage(_webImage!);
    }
    // 2. Si hem triat foto nova en MÒBIL
    else if (!kIsWeb && _imageFile != null) {
      return FileImage(File(_imageFile!.path));
    }
    // 3. Si no hem triat res, mostrem la que ja tenia l'usuari (si en té)
    else if (widget.currentMember.fotoUrl != null &&
        widget.currentMember.fotoUrl!.isNotEmpty) {
      return NetworkImage(widget.currentMember.fotoUrl!);
    }
    // 4. Si no té res, retornem null (es mostrarà la icona per defecte)
    return null;
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
                  // --- SECCIÓ FOTO DE PERFIL (NOU) ---
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: _pickImage, // Al tocar la foto, obrim galeria
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarImage(),
                            child: (_getAvatarImage() == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                        // Botonet blau amb la càmera
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

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
