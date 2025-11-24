// lib/pages/admin/family_manager_page.dart
import 'package:abenceapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FamilyManagerPage extends StatefulWidget {
  const FamilyManagerPage({super.key});

  @override
  State<FamilyManagerPage> createState() => _FamilyManagerPageState();
}

class _FamilyManagerPageState extends State<FamilyManagerPage> {
  // Llistes per a guardar els usuaris carregats
  List<MemberModel> _allSeniors = [];
  List<MemberModel> _allChildren = [];
  bool _isLoading = true;

  // Selecció actual
  MemberModel? _selectedSenior;
  // Mapa per a controlar quins nens estan seleccionats per al Senior actual
  // Clau: ID del nen, Valor: true/false
  Map<String, bool> _childrenSelection = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('membres')
          .get();
      final allMembers = snapshot.docs
          .map((doc) => MemberModel.fromJson(doc))
          .toList();

      setState(() {
        // Filtrem per rols usant els getters del model
        _allSeniors = allMembers.where((m) => m.isSenior).toList();
        _allChildren = allMembers.where((m) => m.isChild).toList();

        // Ordenem alfabèticament
        _allSeniors.sort((a, b) => a.mote.compareTo(b.mote));
        _allChildren.sort((a, b) => a.mote.compareTo(b.mote));

        _isLoading = false;
      });
    } catch (e) {
      print('Error carregant dades: $e');
      setState(() => _isLoading = false);
    }
  }

  // Quan seleccionem un Senior, carreguem la seua configuració actual
  void _onSeniorSelected(MemberModel? senior) {
    if (senior == null) {
      setState(() {
        _selectedSenior = null;
        _childrenSelection.clear();
      });
      return;
    }

    // Creem el mapa d'estat basat en els fills que JA té vinculats
    Map<String, bool> newSelection = {};
    for (var child in _allChildren) {
      // Està aquest nen en la llista 'linkedChildrenUids' del senior?
      bool isLinked = senior.linkedChildrenUids.contains(child.id);
      newSelection[child.id] = isLinked;
    }

    setState(() {
      _selectedSenior = senior;
      _childrenSelection = newSelection;
    });
  }

  Future<void> _saveChanges() async {
    if (_selectedSenior == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Construïm la nova llista d'IDs
      List<String> newLinkedIds = [];
      _childrenSelection.forEach((childId, isSelected) {
        if (isSelected) {
          newLinkedIds.add(childId);
        }
      });

      // 2. Actualitzem Firestore
      await FirebaseFirestore.instance
          .collection('membres')
          .doc(_selectedSenior!.id)
          .update({'linkedChildrenUids': newLinkedIds});

      // 3. Actualitzem l'objecte local per a reflectir els canvis
      // (Recarreguem les dades per seguretat)
      await _loadData();
      // Tornem a seleccionar el senior per a refrescar la vista
      final updatedSenior = _allSeniors.firstWhere(
        (s) => s.id == _selectedSenior!.id,
      );
      _onSeniorSelected(updatedSenior);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Família actualitzada correctament!'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestió de Famílies')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '1. Selecciona un Membre Senior (Pare/Tutor):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<MemberModel>(
                    isExpanded: true,
                    hint: const Text('Tria un membre...'),
                    value: _selectedSenior,
                    // Comparem per ID per a evitar errors d'objecte
                    items: _allSeniors.map((senior) {
                      return DropdownMenuItem(
                        value: senior,
                        child: Text(
                          '${senior.mote} (${senior.nom} ${senior.cognoms})',
                        ),
                      );
                    }).toList(),
                    onChanged: _onSeniorSelected,
                  ),

                  const SizedBox(height: 24),

                  if (_selectedSenior != null) ...[
                    const Text(
                      '2. Vincula els nens corresponents:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _allChildren.isEmpty
                          ? const Center(
                              child: Text('No hi ha nens registrats.'),
                            )
                          : ListView.builder(
                              itemCount: _allChildren.length,
                              itemBuilder: (context, index) {
                                final child = _allChildren[index];
                                final isSelected =
                                    _childrenSelection[child.id] ?? false;

                                return CheckboxListTile(
                                  title: Text(child.mote),
                                  subtitle: Text(
                                    '${child.nom} ${child.cognoms} (${child.age} anys)',
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _childrenSelection[child.id] =
                                          value ?? false;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Vinculacions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Selecciona un Senior per a començar.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
