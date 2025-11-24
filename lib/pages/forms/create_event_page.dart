// lib/pages/forms/create_event_page.dart
import 'dart:io';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // Necessari

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dressCodeController = TextEditingController();

  final List<TextEditingController> _menuControllers = [];

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String _selectedIconName = 'default';

  File? _selectedImage;

  // --- VARIABLES PER AL PDF ADJUNT ---
  File? _attachedFile;
  String? _attachedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dressCodeController.dispose();
    for (var c in _menuControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  // --- SELECCIONAR PDF ---
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFile = File(result.files.single.path!);
        _attachedFileName = result.files.single.name;
      });
    }
  }

  void _addMenuOption() {
    setState(() => _menuControllers.add(TextEditingController()));
  }

  void _removeMenuOption(int index) {
    setState(() {
      _menuControllers[index].dispose();
      _menuControllers.removeAt(index);
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
    );
    if (pickedTime == null) return;
    setState(() {
      _startDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = null;
    });
  }

  Future<void> _selectEndDate(BuildContext context) async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primer selecciona la data d\'inici.')),
      );
      return;
    }
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 7)),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _startDate!.add(const Duration(hours: 2)),
      ),
    );
    if (pickedTime == null) return;
    final tempEndDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (tempEndDate.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La data de fi ha de ser posterior a l\'inici.'),
        ),
      );
      return;
    }
    setState(() => _endDate = tempEndDate);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falta data d\'inici.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Pujar Imatge (si n'hi ha)
      String? uploadedImageUrl;
      if (_selectedImage != null) {
        uploadedImageUrl = await _firestoreService.uploadCoverImage(
          _selectedImage!,
          'event_covers',
        );
      }

      // 2. Pujar PDF (si n'hi ha)
      String? uploadedPdfUrl;
      if (_attachedFile != null) {
        // Reutilitzem la funció de pujar PDF, però els posarà a 'documents/'.
        // Si vols una carpeta separada, hauries de crear una altra funció, però per ara serveix.
        uploadedPdfUrl = await _firestoreService.uploadPdfFile(_attachedFile!);
      }

      final List<String> menuOptions = _menuControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      await _firestoreService.addEvent(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _locationController.text.trim(),
        _startDate!,
        iconName: _selectedIconName,
        endDate: _endDate,
        dressCode: _dressCodeController.text.trim().isEmpty
            ? null
            : _dressCodeController.text.trim(),
        menuOptions: menuOptions,
        imageUrl: uploadedImageUrl,
        // Passem els adjunts
        attachedFileUrl: uploadedPdfUrl,
        attachedFileName: _attachedFileName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esdeveniment creat!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nou Esdeveniment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Pujar Foto de Portada (Opcional)",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  if (_selectedImage != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      child: const Text(
                        "Eliminar foto",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // --- BOTÓ PUJAR PDF ADJUNT ---
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.attach_file,
                        color: Colors.blue,
                      ),
                      title: Text(
                        _attachedFileName ?? 'Adjuntar PDF (Opcional)',
                      ),
                      subtitle: _attachedFileName != null
                          ? const Text("Document temporal de l'esdeveniment")
                          : null,
                      trailing: _attachedFile != null
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() {
                                _attachedFile = null;
                                _attachedFileName = null;
                              }),
                            )
                          : const Icon(Icons.add),
                      onTap: _pickPdf,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Títol',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v!.isEmpty ? 'Camp obligatori' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ubicació',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => v!.isEmpty ? 'Camp obligatori' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dressCodeController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Vestimenta',
                      prefixIcon: Icon(Icons.checkroom),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descripció',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Camp obligatori' : null,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectStartDate(context),
                          child: Text(
                            _startDate == null
                                ? 'INICI'
                                : DateFormat('dd/MM HH:mm').format(_startDate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectEndDate(context),
                          child: Text(
                            _endDate == null
                                ? 'FI (+2h)'
                                : DateFormat('dd/MM HH:mm').format(_endDate!),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Opcions de Menú',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ..._menuControllers.asMap().entries.map((entry) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Opció ${entry.key + 1}',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeMenuOption(entry.key),
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addMenuOption,
                    icon: const Icon(Icons.add),
                    label: const Text('Afegir Opció'),
                  ),

                  const Divider(height: 32),
                  Text(
                    'Icona (si no hi ha foto)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: eventIcons.entries.map((entry) {
                        final bool isSelected = _selectedIconName == entry.key;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIconName = entry.key),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              entry.value,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              size: 30,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text(
                      'Crear Esdeveniment',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
