// lib/pages/details/event_detail_page.dart
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/pages/details/attendance_check_page.dart';
import 'package:abenceapp/pages/forms/edit_event_page.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:abenceapp/pages/details/pdf_viewer_page.dart';
// Import del servei Excel
import 'package:abenceapp/services/excel_service.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  MemberModel? _userProfile;
  final List<MemberModel> _childrenProfiles = [];
  bool _isLoadingFamily = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await _firestoreService.getMemberDetails(
        _currentUser.uid,
      );
      _userProfile = userDoc;
      _isAdmin = userDoc.isAdmin;

      if (_userProfile!.isSenior &&
          _userProfile!.linkedChildrenUids.isNotEmpty) {
        for (String childId in _userProfile!.linkedChildrenUids) {
          try {
            final childDoc = await _firestoreService.getMemberDetails(childId);
            _childrenProfiles.add(childDoc);
          } catch (e) {
            /*...*/
          }
        }
      }
    } catch (e) {
      /*...*/
    } finally {
      if (mounted) setState(() => _isLoadingFamily = false);
    }
  }

  // --- FUNCIONS LOGIQUES (Mantenim les que ja teniem) ---
  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esborrar Esdeveniment'),
        content: const Text('Estàs segur?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esborrar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteEvent(widget.event.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Esdeveniment esborrat.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _removeParticipant(
    dynamic participantMap,
    bool isManualGuest,
  ) async {
    final name = isManualGuest
        ? participantMap['name']
        : participantMap['mote'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expulsar Participant'),
        content: Text('Vols eliminar a "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (isManualGuest) {
          await _firestoreService.removeManualGuest(
            widget.event.id,
            Map<String, dynamic>.from(participantMap),
          );
        } else {
          await _firestoreService.removeAttendee(
            widget.event.id,
            participantMap['uid'],
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name eliminat.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showMultiJoinDialog(EventModel liveEvent) async {
    if (_userProfile == null) return;
    Map<String, bool> selectionState = {};
    Map<String, String?> menuSelections = {};
    var myEntry = liveEvent.attendees.firstWhere(
      (a) => a['uid'] == _currentUser!.uid,
      orElse: () => null,
    );
    selectionState[_userProfile!.id] = myEntry != null;
    if (myEntry != null) {
      menuSelections[_userProfile!.id] = myEntry['selection'];
    }
    for (var child in _childrenProfiles) {
      var childEntry = liveEvent.attendees.firstWhere(
        (a) => a['uid'] == child.id,
        orElse: () => null,
      );
      selectionState[child.id] = childEntry != null;
      if (childEntry != null) {
        menuSelections[child.id] = childEntry['selection'];
      }
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Gestionar Assistència'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (liveEvent.menuOptions.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          "⚠️ Requereix triar opció.",
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    _buildFamilyRow(
                      context: context,
                      setStateDialog: setStateDialog,
                      id: _userProfile!.id,
                      name: "${_userProfile!.mote} (Jo)",
                      selectionState: selectionState,
                      menuSelections: menuSelections,
                      options: liveEvent.menuOptions,
                    ),
                    const Divider(),
                    if (_childrenProfiles.isNotEmpty)
                      ..._childrenProfiles.map(
                        (child) => _buildFamilyRow(
                          context: context,
                          setStateDialog: setStateDialog,
                          id: child.id,
                          name: "${child.mote} (Fill/a)",
                          isChild: true,
                          selectionState: selectionState,
                          menuSelections: menuSelections,
                          options: liveEvent.menuOptions,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (liveEvent.menuOptions.isNotEmpty) {
                      bool missing = false;
                      selectionState.forEach((id, isSel) {
                        if (isSel &&
                            (menuSelections[id] == null ||
                                menuSelections[id]!.isEmpty)) {
                          missing = true;
                        }
                      });
                      if (missing) return;
                    }
                    Navigator.pop(context);
                    _processFamilyUpdates(
                      selectionState,
                      menuSelections,
                      liveEvent,
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFamilyRow({
    required BuildContext context,
    required Function setStateDialog,
    required String id,
    required String name,
    required Map<String, bool> selectionState,
    required Map<String, String?> menuSelections,
    required List<String> options,
    bool isChild = false,
  }) {
    bool isChecked = selectionState[id] ?? false;
    return Column(
      children: [
        CheckboxListTile(
          title: Text(name),
          secondary: isChild ? const Icon(Icons.child_care) : null,
          value: isChecked,
          onChanged: (v) =>
              setStateDialog(() => selectionState[id] = v ?? false),
        ),
        if (isChecked && options.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Opció',
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              initialValue: menuSelections[id],
              isDense: true,
              items: options
                  .map((op) => DropdownMenuItem(value: op, child: Text(op)))
                  .toList(),
              onChanged: (val) =>
                  setStateDialog(() => menuSelections[id] = val),
            ),
          ),
      ],
    );
  }

  Future<void> _processFamilyUpdates(
    Map<String, bool> finalState,
    Map<String, String?> finalMenus,
    EventModel liveEvent,
  ) async {
    setState(() => _isLoading = true);
    try {
      bool wasIn = liveEvent.attendees.any((a) => a['uid'] == _userProfile!.id);
      bool wantsIn = finalState[_userProfile!.id] ?? false;
      String? menu = finalMenus[_userProfile!.id];
      if (wantsIn) {
        await _firestoreService.joinEvent(widget.event.id, selection: menu);
      } else if (wasIn && !wantsIn)
        await _firestoreService.leaveEvent(widget.event.id);
      for (var child in _childrenProfiles) {
        bool wasChildIn = liveEvent.attendees.any((a) => a['uid'] == child.id);
        bool wantsChildIn = finalState[child.id] ?? false;
        String? childMenu = finalMenus[child.id];
        if (wantsChildIn) {
          await _firestoreService.joinEventForChild(
            widget.event.id,
            child,
            selection: childMenu,
          );
        } else if (wasChildIn && !wantsChildIn)
          await _firestoreService.leaveEventForChild(widget.event.id, child);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Llista actualitzada!'),
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

  Future<void> _showAddGuestDialog(EventModel liveEvent) async {
    final TextEditingController guestNameController = TextEditingController();
    String? selectedMenu;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Afegir Convidat'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nom:'),
                const SizedBox(height: 8),
                TextField(
                  controller: guestNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                if (liveEvent.menuOptions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Menú',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedMenu,
                    items: liveEvent.menuOptions
                        .map(
                          (op) => DropdownMenuItem(value: op, child: Text(op)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setStateDialog(() => selectedMenu = val),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel·lar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (guestNameController.text.trim().isEmpty) return;
                  if (liveEvent.menuOptions.isNotEmpty &&
                      selectedMenu == null) {
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await _firestoreService.addManualGuest(
                      widget.event.id,
                      guestNameController.text.trim(),
                      selection: selectedMenu,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Convidat afegit!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    /*...*/
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: const Text('Afegir'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _joinSimple(EventModel liveEvent) async {
    if (liveEvent.menuOptions.isEmpty) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.joinEvent(widget.event.id);
      } catch (e) {
        /*...*/
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }
    String? selectedMenu;
    var myEntry = liveEvent.attendees.firstWhere(
      (a) => a['uid'] == _currentUser!.uid,
      orElse: () => null,
    );
    if (myEntry != null) selectedMenu = myEntry['selection'];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Tria una opció"),
            content: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Menú',
                border: OutlineInputBorder(),
              ),
              initialValue: selectedMenu,
              items: liveEvent.menuOptions
                  .map((op) => DropdownMenuItem(value: op, child: Text(op)))
                  .toList(),
              onChanged: (val) => setStateDialog(() => selectedMenu = val),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel·lar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedMenu),
                child: const Text("Confirmar"),
              ),
            ],
          );
        },
      ),
    );
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.joinEvent(widget.event.id, selection: result);
      } catch (e) {
        /*...*/
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _leaveSimple() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.leaveEvent(widget.event.id);
    } catch (e) {
      /*...*/
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.events.doc(widget.event.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Esdeveniment no trobat")),
          );
        }

        final EventModel liveEvent = EventModel.fromJson(snapshot.data!);
        final String startDateStr = DateFormat(
          'd MMMM - HH:mm',
          'ca',
        ).format(liveEvent.date.toDate());
        String endDateStr = liveEvent.endDate != null
            ? (liveEvent.endDate!.toDate().day == liveEvent.date.toDate().day
                  ? 'Fins a les ${DateFormat('HH:mm').format(liveEvent.endDate!.toDate())}'
                  : 'Fins al ${DateFormat('d MMM - HH:mm', 'ca').format(liveEvent.endDate!.toDate())}')
            : '+2h aprox.';
        bool isAttending = false;
        if (_currentUser != null) {
          isAttending = liveEvent.attendees.any(
            (a) => a['uid'] == _currentUser.uid,
          );
        }
        bool isExpired = liveEvent.endDate != null
            ? liveEvent.endDate!.toDate().isBefore(DateTime.now())
            : liveEvent.date
                  .toDate()
                  .add(const Duration(hours: 2))
                  .isBefore(DateTime.now());
        bool showFamilyButton =
            !_isLoadingFamily &&
            _userProfile != null &&
            _userProfile!.isSenior &&
            _childrenProfiles.isNotEmpty;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    liveEvent.title,
                    style: const TextStyle(
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  background:
                      liveEvent.imageUrl != null &&
                          liveEvent.imageUrl!.isNotEmpty
                      ? Image.network(liveEvent.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            getIconData(liveEvent.iconName, type: 'event'),
                            size: 100,
                            color: Colors.black38,
                          ),
                        ),
                ),
                actions: [
                  if (_isAdmin) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditEventPage(event: liveEvent),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: _deleteEvent,
                    ),
                  ],
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoRow(
                          context,
                          icon: Icons.location_on,
                          text: liveEvent.location,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          icon: Icons.access_time,
                          text: "$startDateStr\n$endDateStr",
                        ),
                        const SizedBox(height: 12),
                        if (liveEvent.dressCode != null &&
                            liveEvent.dressCode!.isNotEmpty) ...[
                          _buildInfoRow(
                            context,
                            icon: Icons.checkroom,
                            text: "Vestimenta: ${liveEvent.dressCode}",
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (liveEvent.menuOptions.isNotEmpty) ...[
                          _buildInfoRow(
                            context,
                            icon: Icons.restaurant_menu,
                            text:
                                "Opcions: ${liveEvent.menuOptions.join(', ')}",
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Divider(height: 30),
                        Text(
                          liveEvent.description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontSize: 16),
                        ),

                        // --- BOTÓ VEURE ADJUNT ---
                        if (liveEvent.attachedFileUrl != null &&
                            liveEvent.attachedFileUrl!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 20, bottom: 10),
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerPage(
                                    pdfUrl: liveEvent.attachedFileUrl!,
                                    title:
                                        liveEvent.attachedFileName ??
                                        'Document Adjunt',
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.description),
                              label: Text(
                                "Veure: ${liveEvent.attachedFileName ?? 'Document'}",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),

                        if (!isExpired) ...[
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (showFamilyButton)
                            ElevatedButton.icon(
                              onPressed: () => _showMultiJoinDialog(liveEvent),
                              icon: const Icon(Icons.family_restroom),
                              label: const Text(
                                'Gestionar Família / Apuntar-se',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed:
                                  (isAttending && liveEvent.menuOptions.isEmpty)
                                  ? _leaveSimple
                                  : () => _joinSimple(liveEvent),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAttending
                                    ? Colors.grey[800]
                                    : Theme.of(context).colorScheme.secondary,
                                foregroundColor: isAttending
                                    ? Colors.white
                                    : Colors.black,
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              child: Text(
                                isAttending
                                    ? (liveEvent.menuOptions.isNotEmpty
                                          ? 'Modificar Opció / Esborrar'
                                          : 'Esborrar-me')
                                    : 'Apuntar-me',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isAttending && liveEvent.menuOptions.isNotEmpty)
                            TextButton(
                              onPressed: _leaveSimple,
                              child: const Text(
                                "No hi aniré (Esborrar-me)",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, color: Colors.grey),
                                SizedBox(width: 8),
                                Text(
                                  "Aquest esdeveniment ja ha finalitzat.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showAddGuestDialog(liveEvent),
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('Afegir Convidat'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),

                        if (_isAdmin) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const Text(
                            "Gestió Admin",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AttendanceCheckPage(
                                              eventId: liveEvent.id,
                                              eventTitle: liveEvent.title,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.playlist_add_check),
                                  label: const Text('Pasar Llista'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[800],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // --- NOU BOTÓ: EXPORTAR EXCEL ---
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await ExcelService().exportEventAttendees(
                                        liveEvent,
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.table_view,
                                    color: Colors.green,
                                  ),
                                  label: const Text('Excel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const Divider(height: 40),
                        Text(
                          'Assistents (${liveEvent.attendees.length + liveEvent.manualGuests.length})',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),
                        if (liveEvent.attendees.isEmpty &&
                            liveEvent.manualGuests.isEmpty)
                          const Text('Encara no hi ha ningú apuntat.'),

                        ...liveEvent.attendees.map((attendee) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              backgroundImage:
                                  attendee['fotoUrl'] != null &&
                                      attendee['fotoUrl'].isNotEmpty
                                  ? NetworkImage(attendee['fotoUrl'])
                                  : null,
                              child:
                                  (attendee['fotoUrl'] == null ||
                                      attendee['fotoUrl'].isEmpty)
                                  ? Text(attendee['mote'][0])
                                  : null,
                            ),
                            title: Text(
                              attendee['mote'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: attendee['selection'] != null
                                ? Text(
                                    "Opció: ${attendee['selection']}",
                                    style: const TextStyle(color: Colors.green),
                                  )
                                : null,
                            trailing: _isAdmin
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _removeParticipant(attendee, false),
                                  )
                                : null,
                          );
                        }),
                        ...liveEvent.manualGuests.map((guest) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey,
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              guest['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Convidat de ${guest['addedByMote'] ?? 'Admin'}",
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                                if (guest['selection'] != null)
                                  Text(
                                    "Opció: ${guest['selection']}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: _isAdmin
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _removeParticipant(guest, true),
                                  )
                                : null,
                          );
                        }),
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

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}
