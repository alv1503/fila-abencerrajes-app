// lib/pages/forms/edit_event_page.dart
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditEventPage extends StatefulWidget {
  final EventModel event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _dressCodeController;

  final List<TextEditingController> _menuControllers = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedIconName = 'default';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(
      text: widget.event.description,
    );
    _locationController = TextEditingController(text: widget.event.location);
    _dressCodeController = TextEditingController(
      text: widget.event.dressCode ?? '',
    );

    _startDate = widget.event.date.toDate();
    _endDate = widget.event.endDate?.toDate();
    _selectedIconName = widget.event.iconName ?? 'default';

    for (String option in widget.event.menuOptions) {
      _menuControllers.add(TextEditingController(text: option));
    }
  }

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

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate!),
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
    if (_startDate == null) return;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 7)),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _endDate != null
          ? TimeOfDay.fromDateTime(_endDate!)
          : TimeOfDay.fromDateTime(_startDate!.add(const Duration(hours: 2))),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data fi incorrecta.')));
      return;
    }
    setState(() => _endDate = tempEndDate);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> menuOptions = _menuControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      await _firestoreService.updateEvent(
        widget.event.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _startDate!,
        iconName: _selectedIconName,
        endDate: _endDate,
        dressCode: _dressCodeController.text.trim().isEmpty
            ? null
            : _dressCodeController.text.trim(),
        menuOptions: menuOptions,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualitzat!'),
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

  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return 'Camp obligatori';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Esdeveniment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    // --- CANVI ---
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Títol',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    // --- CANVI ---
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ubicació',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dressCodeController,
                    // --- CANVI ---
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Vestimenta',
                      prefixIcon: Icon(Icons.checkroom),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    // --- CANVI ---
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descripció',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                    validator: _validateNotEmpty,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectStartDate(context),
                          child: Text(
                            'INICI: ${DateFormat('dd/MM HH:mm').format(_startDate!)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectEndDate(context),
                          child: Text(
                            'FI: ${_endDate == null ? 'Auto' : DateFormat('dd/MM HH:mm').format(_endDate!)}',
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
                            // --- CANVI ---
                            textCapitalization: TextCapitalization.sentences,
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

                  const SizedBox(height: 32),

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
                    onPressed: _saveChanges,
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
