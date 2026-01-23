// lib/pages/forms/create_event_page.dart

import 'package:abenceapp/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/utils/icon_helper.dart';

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
  DateTime? _endDate; // Opcional
  bool _isLoading = false;
  String _selectedIconName = 'default'; // Icono por defecto

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dressCodeController.dispose();
    for (var controller in _menuControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- GESTIÓN DE FECHAS ---
  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart 
        ? (_startDate ?? now) 
        : (_endDate ?? _startDate ?? now);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            _startDate = finalDateTime;
            // Si la fecha final es anterior a la nueva inicial, la reseteamos
            if (_endDate != null && _endDate!.isBefore(_startDate!)) {
              _endDate = null;
            }
          } else {
            _endDate = finalDateTime;
          }
        });
      }
    }
  }

  // --- GESTIÓN DE MENÚ ---
  void _addMenuOption() {
    setState(() {
      _menuControllers.add(TextEditingController());
    });
  }

  void _removeMenuOption(int index) {
    setState(() {
      _menuControllers[index].dispose();
      _menuControllers.removeAt(index);
    });
  }

  // --- GUARDAR EVENTO ---
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has de seleccionar una data d\'inici')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Recopilar opciones de menú limpias
      List<String> menuOptions = _menuControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      await _firestoreService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _startDate!,
        endDate: _endDate,
        dressCode: _dressCodeController.text.trim().isNotEmpty 
            ? _dressCodeController.text.trim() 
            : null,
        menuOptions: menuOptions,
        iconName: _selectedIconName, // Solo guardamos el nombre del icono
        imageFile: null, // Ya no enviamos imagen
        attachedFile: null, // Ya no enviamos PDF
        attachedFileName: null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esdeveniment creat correctament!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creant esdeveniment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Nou Esdeveniment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Icono Principal
                  Center(
                    child: Column(
                      children: [
                        Text("Icona de l'esdeveniment", style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            // Mostrar selector de iconos simple
                             // Nota: Asumo que tienes una lista de iconos. 
                             // Si no quieres complicarte, usa un set predefinido aquí mismo
                            _showIconPicker();
                          },
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              getIconData(_selectedIconName, type: 'event'),
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const Text("Prem per canviar", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Datos Básicos
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Títol', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Necessari' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Ubicació', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                    validator: (v) => v == null || v.isEmpty ? 'Necessari' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Fechas
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Inici', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(_startDate != null ? dateFormat.format(_startDate!) : 'Seleccionar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Final (Opcional)', border: OutlineInputBorder()),
                            child: Text(_endDate != null ? dateFormat.format(_endDate!) : '-'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripció', border: OutlineInputBorder(), alignLabelWithHint: true),
                    validator: (v) => v == null || v.isEmpty ? 'Necessari' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _dressCodeController,
                    decoration: const InputDecoration(labelText: 'Dress Code (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.checkroom)),
                  ),

                  // 4. Menú
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Opcions de Menú', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: _addMenuOption, icon: const Icon(Icons.add_circle, color: Colors.green)),
                    ],
                  ),
                  if (_menuControllers.isEmpty)
                    const Text('No hi ha opcions de menú.', style: TextStyle(color: Colors.grey)),
                  
                  ..._menuControllers.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: entry.value,
                              decoration: InputDecoration(labelText: 'Opció ${entry.key + 1}', border: const OutlineInputBorder()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeMenuOption(entry.key),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('CREAR ESDEVENIMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // Selector simple de iconos
  void _showIconPicker() {
    // Lista completa de claves definidas en icon_helper.dart
    final List<String> availableIcons = [
      'default', 
      'party', 'birthday', 'music', 'dance', 'beer', 'wine', // Social
      'dinner', 'lunch', 'bbq', 'coffee', // Comida
      'sports', 'gym', 'hiking', 'beach', 'travel', // Activos
      'meeting', 'work', 'study', 'presentation', // Serios
      'cinema', 'game', 'photography', 'shopping' // Hobbies
    ]; 
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400, // Un poco más alto para que quepan bien
          child: Column(
            children: [
              const Text("Tria una icona", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, // 5 iconos por fila
                    crossAxisSpacing: 15, 
                    mainAxisSpacing: 15
                  ),
                  itemCount: availableIcons.length,
                  itemBuilder: (context, index) {
                    final iconKey = availableIcons[index];
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedIconName = iconKey);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedIconName == iconKey ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: _selectedIconName == iconKey ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
                        ),
                        child: Icon(
                          getIconData(iconKey, type: 'event'), 
                          size: 28, 
                          color: Colors.black87
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}