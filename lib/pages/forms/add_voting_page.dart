// lib/pages/forms/add_voting_page.dart
import 'dart:io';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // Necessari

class AddVotingPage extends StatefulWidget {
  const AddVotingPage({super.key});

  @override
  State<AddVotingPage> createState() => _AddVotingPageState();
}

class _AddVotingPageState extends State<AddVotingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];

  DateTime? _endDate;
  bool _isLoading = false;
  String _selectedIconName = 'default';
  bool _allowMultipleChoices = false;

  File? _selectedImage;

  // --- VARIABLES PER AL PDF ADJUNT ---
  File? _attachedFile;
  String? _attachedFileName;

  @override
  void initState() {
    super.initState();
    _addOptionField();
    _addOptionField();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOptionField() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOptionField(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
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

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (pickedTime == null) return;
    setState(() {
      _endDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveVoting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falta data de tancament.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> options = _optionControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (options.length < 2) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mínim 2 opcions.')));
        setState(() => _isLoading = false);
        return;
      }

      // 1. Pujar Imatge
      String? uploadedImageUrl;
      if (_selectedImage != null) {
        uploadedImageUrl = await _firestoreService.uploadCoverImage(
          _selectedImage!,
          'voting_covers',
        );
      }

      // 2. Pujar PDF
      String? uploadedPdfUrl;
      if (_attachedFile != null) {
        uploadedPdfUrl = await _firestoreService.uploadPdfFile(_attachedFile!);
      }

      await _firestoreService.addVoting(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        endDate: _endDate!,
        options: options,
        iconName: _selectedIconName,
        allowMultipleChoices: _allowMultipleChoices,
        imageUrl: uploadedImageUrl,
        // Passem els adjunts
        attachedFileUrl: uploadedPdfUrl,
        attachedFileName: _attachedFileName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votació creada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return 'Camp obligatori';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nova Votació')),
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
                          ? const Text("Document temporal de la votació")
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
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Descripció'),
                    maxLines: 3,
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate == null
                          ? 'Seleccionar Data Tancament'
                          : DateFormat('dd/MM/yy - HH:mm').format(_endDate!),
                    ),
                    onPressed: () => _selectDateTime(context),
                  ),
                  const Divider(height: 32),

                  SwitchListTile(
                    title: const Text('Permetre Selecció Múltiple'),
                    value: _allowMultipleChoices,
                    onChanged: (val) =>
                        setState(() => _allowMultipleChoices = val),
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
                      children: votingIcons.entries.map((entry) {
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
                  const Divider(height: 32),

                  const Text(
                    'Opcions de Vot',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._optionControllers.asMap().entries.map((entry) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Opció ${entry.key + 1}',
                            ),
                            validator: entry.key < 2 ? _validateNotEmpty : null,
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeOptionField(entry.key),
                          ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Afegir Opció'),
                    onPressed: _addOptionField,
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveVoting,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text(
                      'Crear Votació',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
