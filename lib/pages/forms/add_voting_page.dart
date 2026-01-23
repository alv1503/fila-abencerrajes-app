// lib/pages/forms/add_voting_page.dart
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddVotingPage extends StatefulWidget {
  const AddVotingPage({super.key});

  @override
  State<AddVotingPage> createState() => _AddVotingPageState();
}

class _AddVotingPageState extends State<AddVotingPage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _optionsControllers = [];

  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isLoading = false;
  
  // Icono seleccionado
  String _selectedIconName = 'vote_poll';

  @override
  void initState() {
    super.initState();
    // Empezamos con 2 opciones por defecto
    _addOption();
    _addOption();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var c in _optionsControllers) c.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionsControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionsControllers.length > 2) {
      setState(() {
        _optionsControllers[index].dispose();
        _optionsControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mínim 2 opcions necessàries.')),
      );
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );
      if (time != null && mounted) {
        setState(() {
          _endDate = date;
          _endTime = time;
        });
      }
    }
  }

  Future<void> _createVoting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tria una data de finalització')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final options = _optionsControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (options.length < 2) {
        throw 'Mínim 2 opcions vàlides.';
      }

      final endDateTime = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day,
        _endTime!.hour, _endTime!.minute,
      );

      // Crear votación
      await _firestoreService.votings.add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'options': options,
        'votes': {}, // Mapa vacío de votos
        'createdAt': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(endDateTime),
        'createdBy': user.uid,
        'iconName': _selectedIconName, // Guardamos el icono
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votació creada!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Selector de Iconos para Votaciones
  void _showIconPicker() {
    final List<String> votingIcons = ['vote_poll', 'vote_yesno', 'vote_check', 'vote_star'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            children: [
              const Text("Tria una icona", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 15, mainAxisSpacing: 15
                  ),
                  itemCount: votingIcons.length,
                  itemBuilder: (context, index) {
                    final iconKey = votingIcons[index];
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
                        child: Icon(getIconData(iconKey, type: 'voting'), size: 30, color: Colors.black87),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Votació')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   // Icono
                  Center(
                    child: InkWell(
                      onTap: _showIconPicker,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          getIconData(_selectedIconName, type: 'voting'),
                          size: 35,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Títol', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Necessari' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descripció (Opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: Text(_endDate == null 
                      ? 'Tria data de finalització' 
                      : 'Finalitza: ${_endDate!.day}/${_endDate!.month} a les ${_endTime!.format(context)}'
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
                    onTap: _pickEndDate,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Opcions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: _addOption, icon: const Icon(Icons.add_circle, color: Colors.green)),
                    ],
                  ),
                  
                  ..._optionsControllers.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: 'Opció ${entry.key + 1}',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'No pot estar buit' : null,
                            ),
                          ),
                          if (_optionsControllers.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeOption(entry.key),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _createVoting,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('CREAR VOTACIÓ'),
                  ),
                ],
              ),
            ),
    );
  }
}