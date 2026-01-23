// lib/pages/forms/edit_event_page.dart
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditEventPage extends StatefulWidget {
  final EventModel event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _dressCodeController;

  late DateTime _startDate;
  DateTime? _endDate;
  final List<TextEditingController> _menuControllers = [];
  
  bool _isLoading = false;
  String _selectedIconName = 'default';

  @override
  void initState() {
    super.initState();
    // Cargar datos existentes
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _dressCodeController = TextEditingController(text: widget.event.dressCode ?? '');
    
    _startDate = widget.event.date.toDate();
    if (widget.event.endDate != null) {
      _endDate = widget.event.endDate!.toDate();
    }
    
    _selectedIconName = widget.event.iconName ?? 'default';

    // Cargar menú
    for (String op in widget.event.menuOptions) {
      _menuControllers.add(TextEditingController(text: op));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dressCodeController.dispose();
    for (var c in _menuControllers) c.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _startDate : (_endDate ?? _startDate);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newDate = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        setState(() {
          if (isStart) _startDate = newDate;
          else _endDate = newDate;
        });
      }
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      List<String> menuOptions = _menuControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await _firestoreService.events.doc(widget.event.id).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'dressCode': _dressCodeController.text.trim(),
        'date': Timestamp.fromDate(_startDate),
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'menuOptions': menuOptions,
        'iconName': _selectedIconName,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Canvis guardats correctament')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Selector de Iconos (Igual que en CreateEventPage)
  void _showIconPicker() {
    final List<String> availableIcons = [
      'default', 'party', 'birthday', 'music', 'dance', 'beer', 'wine', 
      'dinner', 'lunch', 'bbq', 'coffee', 
      'sports', 'gym', 'hiking', 'beach', 'travel', 
      'meeting', 'work', 'study', 'presentation',
      'cinema', 'game', 'photography', 'shopping'
    ]; 
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text("Tria una icona", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, crossAxisSpacing: 15, mainAxisSpacing: 15
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
                        child: Icon(getIconData(iconKey, type: 'event'), size: 28, color: Colors.black87),
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Esdeveniment')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Icono
                Center(
                  child: Column(
                    children: [
                      const Text("Icona", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _showIconPicker,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Títol', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Necessari' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Ubicació', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // Fechas
                Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Inici', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(dateFormat.format(_startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Final', border: OutlineInputBorder()),
                            child: Text(_endDate != null ? dateFormat.format(_endDate!) : '-'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripció', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                 TextFormField(
                  controller: _dressCodeController,
                  decoration: const InputDecoration(labelText: 'Dress Code', border: OutlineInputBorder()),
                ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Menú', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: _addMenuOption, icon: const Icon(Icons.add_circle, color: Colors.green)),
                  ],
                ),
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
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15)
                  ),
                  child: const Text('GUARDAR CANVIS'),
                ),
              ],
            ),
          ),
    );
  }
}