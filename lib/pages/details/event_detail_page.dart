// lib/pages/details/event_detail_page.dart

import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/services/excel_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:abenceapp/pages/forms/edit_event_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ExcelService _excelService = ExcelService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Instancia directa para gestionar hijos

  bool _isLoading = false;
  MemberModel? _userProfile;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await _firestoreService.getMemberDetails(_currentUser.uid);
      if (mounted) {
        setState(() {
          _userProfile = userDoc;
          _isAdmin = userDoc.isAdmin;
        });
      }
    } catch (e) {
      debugPrint("Error carregant usuari: $e");
    }
  }

  // --- CABECERA LIMPIA SIN IMAGEN ---
  Widget _buildHeader(EventModel liveEvent) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).primaryColor, // Color corporativo sólido
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForEvent(liveEvent),
              size: 80,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForEvent(EventModel event) {
    if (event.iconName != null && event.iconName!.isNotEmpty) {
      try {
        return getIconData(event.iconName!, type: 'event');
      } catch (_) {}
    }
    return Icons.event;
  }

  // --- MENÚ VISUAL ---
  Future<String?> _showMenuSelectionDialog(List<String> options, {String title = "Tria una opció"}) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return InkWell(
                      onTap: () => Navigator.pop(context, option),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.restaurant_menu, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 15),
                            Expanded(child: Text(option, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel·lar", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTONES STANDARD ---
  Future<void> _joinEvent(EventModel liveEvent) async {
    String? selectedMenu;
    if (liveEvent.menuOptions.isNotEmpty) {
      selectedMenu = await _showMenuSelectionDialog(liveEvent.menuOptions, title: "Què vols menjar?");
      if (selectedMenu == null) return;
    }
    setState(() => _isLoading = true);
    try {
      await _firestoreService.joinEvent(widget.event.id, selection: selectedMenu);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addManualGuest(EventModel liveEvent) async {
    if (_userProfile == null) return;
    final TextEditingController nameController = TextEditingController();
    
    final String? guestName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Afegir Convidat"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nom i Cognoms", hintText: "Ex: Pepe García", border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel·lar")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) Navigator.pop(context, nameController.text.trim());
            },
            child: const Text("Continuar"),
          ),
        ],
      ),
    );

    if (guestName == null) return;

    String? selectedMenu;
    if (liveEvent.menuOptions.isNotEmpty) {
      selectedMenu = await _showMenuSelectionDialog(liveEvent.menuOptions, title: "Menú per a $guestName");
      if (selectedMenu == null) return; 
    }

    setState(() => _isLoading = true);
    try {
      await _firestoreService.addManualGuest(
        widget.event.id, 
        guestName, 
        _userProfile!.id, 
        _userProfile!.mote.isNotEmpty ? _userProfile!.mote : _userProfile!.nom,
        selection: selectedMenu
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveEvent() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.leaveEvent(widget.event.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA NUEVA: GESTIÓN DE HIJOS ---
  Future<void> _manageChildren(EventModel liveEvent) async {
    if (_userProfile == null || _userProfile!.linkedChildrenUids.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Obtener datos de los hijos
      // Nota: 'whereIn' soporta máx 10 items.
      final QuerySnapshot childrenSnap = await _db
          .collection('membres')
          .where(FieldPath.documentId, whereIn: _userProfile!.linkedChildrenUids)
          .get();
      
      List<MemberModel> children = childrenSnap.docs.map((d) => MemberModel.fromJson(d)).toList();

      if (!mounted) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = false);

      // 2. Mostrar diálogo de selección
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Gestionar Fills"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children.map((child) {
                  // Verificar si ya está en la lista de attendees
                  // liveEvent.attendees es List<dynamic>, casteamos a Map
                  final isAttending = liveEvent.attendees
                      .whereType<Map<String, dynamic>>()
                      .any((a) => a['uid'] == child.id);

                  return ListTile(
                    title: Text(child.nom),
                    subtitle: Text(isAttending ? "Ja apuntat" : "No assisteix"),
                    trailing: isAttending 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                    onTap: () async {
                      Navigator.pop(context); // Cerrar diálogo para procesar
                      if (isAttending) {
                        // Desapuntar hijo
                        await _removeChild(liveEvent, child);
                      } else {
                        // Apuntar hijo
                        await _addChild(liveEvent, child);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tancar")),
            ],
          );
        },
      );
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      debugPrint("Error fills: $e");
    }
  }

  Future<void> _addChild(EventModel liveEvent, MemberModel child) async {
    // Si hay menú, pedirlo
    String? selectedMenu;
    if (liveEvent.menuOptions.isNotEmpty) {
      selectedMenu = await _showMenuSelectionDialog(liveEvent.menuOptions, title: "Menú per a ${child.nom}");
      if (selectedMenu == null) return; // Cancelado
    }

    setState(() => _isLoading = true);
    
    // Objeto Attendee compatible con tu estructura actual
    Map<String, dynamic> newAttendee = {
      'uid': child.id,
      'mote': child.nom, // Usamos nombre como mote para hijos si no tienen mote
      'selection': selectedMenu,
      'registrationDate': Timestamp.now(),
    };

    try {
      await _db.collection('events').doc(liveEvent.id).update({
        'attendees': FieldValue.arrayUnion([newAttendee])
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${child.nom} afegit!")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeChild(EventModel liveEvent, MemberModel child) async {
    setState(() => _isLoading = true);
    
    try {
      // Buscar el objeto exacto en el array para borrarlo
      final attendeesList = List<Map<String, dynamic>>.from(liveEvent.attendees);
      final attendeeToRemove = attendeesList.firstWhere(
        (a) => a['uid'] == child.id, 
        orElse: () => {}
      );

      if (attendeeToRemove.isNotEmpty) {
        await _db.collection('events').doc(liveEvent.id).update({
          'attendees': FieldValue.arrayRemove([attendeeToRemove])
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${child.nom} esborrat.")));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeGuest(Map<String, dynamic> guestData) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Esborrar Convidat"),
        content: Text("Vols esborrar a ${guestData['name']}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.removeManualGuest(widget.event.id, guestData);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esborrar Esdeveniment'),
        content: const Text('Estàs segur? Aquesta acció no es pot desfer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel·lar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Esborrar')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteEvent(widget.event.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esdeveniment esborrat.')));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.events.doc(widget.event.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Scaffold(appBar: AppBar(), body: Center(child: Text("Error: ${snapshot.error}")));
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists) return const Scaffold(body: Center(child: Text("L'esdeveniment ja no existeix")));

        final EventModel liveEvent = EventModel.fromJson(snapshot.data!);
        final String dateStr = DateFormat('d MMMM yyyy - HH:mm', 'ca').format(liveEvent.date.toDate());
        
        final validAttendees = liveEvent.attendees.where((e) => e is Map).toList();
        final validGuests = liveEvent.manualGuests.where((e) => e is Map).toList();
        
        bool amIAttending = false;
        if (_currentUser != null) {
          amIAttending = validAttendees.any((a) => a['uid'] == _currentUser.uid);
        }

        // Verificar si tengo hijos vinculados
        bool hasChildren = _userProfile != null && _userProfile!.linkedChildrenUids.isNotEmpty;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0, 
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(liveEvent.title, style: const TextStyle(color: Colors.white)),
                  background: _buildHeader(liveEvent),
                ),
                actions: [
                  if (_isAdmin) ...[
                    IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventPage(event: liveEvent)))),
                    IconButton(icon: const Icon(Icons.delete_forever, color: Colors.white), onPressed: _deleteEvent),
                  ]
                ],
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.calendar_today, dateStr),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.location_on, liveEvent.location),
                        if (liveEvent.dressCode != null && liveEvent.dressCode!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.checkroom, "Dress Code: ${liveEvent.dressCode}"),
                        ],
                        
                        const Divider(height: 30),
                        
                        Text(liveEvent.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                        
                        const SizedBox(height: 30),

                        // BOTONES DE ACCIÓN (MODIFICADO PARA INCLUIR FILL)
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: amIAttending ? _leaveEvent : () => _joinEvent(liveEvent),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: amIAttending ? Colors.red.shade100 : Theme.of(context).primaryColor,
                                    foregroundColor: amIAttending ? Colors.red : Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 3,
                                  ),
                                  child: Text(amIAttending ? "NO ANIRÉ" : "M'APUNTE!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // BOTÓN DE HIJOS (SOLO SI TIENE HIJOS)
                              if (hasChildren)
                                Expanded(
                                  flex: 1,
                                  child: OutlinedButton(
                                    onPressed: () => _manageChildren(liveEvent),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Icon(Icons.family_restroom), // Icono de familia
                                  ),
                                ),
                              
                              if (hasChildren) const SizedBox(width: 8),

                              // BOTÓN CONVIDAT
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: () => _addManualGuest(liveEvent),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Icon(Icons.person_add),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 15),
                        // Botón Excel
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async {
                              setState(() => _isLoading = true);
                              try {
                                await _excelService.exportEventAttendees(liveEvent);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel generat correctament"), backgroundColor: Colors.green));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Excel: $e"), backgroundColor: Colors.red));
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                            icon: const Icon(Icons.table_view, color: Colors.green),
                            label: const Text("Descarregar Excel d'assistents", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const Divider(height: 40),

                        // LISTA
                        Text("Assistents (${validAttendees.length + validGuests.length})", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        if (validAttendees.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text("Socis", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          ...validAttendees.map((attendee) {
                             final String mote = attendee['mote'] ?? 'Anònim';
                             final String? menu = attendee['selection'];
                             final bool isMe = _currentUser != null && attendee['uid'] == _currentUser.uid;
                             
                             return Card(
                               elevation: 0,
                               color: isMe ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.grey[50],
                               margin: const EdgeInsets.only(bottom: 8),
                               child: ListTile(
                                 leading: CircleAvatar(
                                   backgroundColor: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                                   foregroundColor: isMe ? Colors.white : Colors.black54,
                                   child: Text(mote.isNotEmpty ? mote[0].toUpperCase() : "?"),
                                 ),
                                 title: Text(isMe ? "$mote (Jo)" : mote, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                                 subtitle: menu != null ? Text("Opció: $menu", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500)) : null,
                               ),
                             );
                          }),
                        ],

                        if (validGuests.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text("Convidats", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          ...validGuests.map((guest) {
                            final String name = guest['name'] ?? 'Convidat';
                            final String addedBy = guest['addedByMote'] ?? 'Algú';
                            final String addedById = guest['addedBy'] ?? '';
                            final String? menu = guest['selection'];
                            final bool canDelete = _isAdmin || (_currentUser != null && addedById == _currentUser.uid);

                            return Card(
                              elevation: 0,
                              color: Colors.orange.withOpacity(0.05),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Convidat per: $addedBy"),
                                    if (menu != null) Text("Opció: $menu", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                trailing: canDelete 
                                  ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeGuest(guest)) 
                                  : null,
                              ),
                            );
                          }),
                        ],

                        if (validAttendees.isEmpty && validGuests.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text("Encara no hi ha ningú apuntat.", style: TextStyle(color: Colors.grey))),
                          ),
                          
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}