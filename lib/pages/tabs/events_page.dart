// lib/pages/tabs/events_page.dart
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/pages/details/event_detail_page.dart';
import 'package:abenceapp/pages/forms/create_event_page.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:abenceapp/pages/details/past_events_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdminStatus();
  }

  // Mantenim açò per al botó d'historial (opcional)
  Future<void> _loadAdminStatus() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('membres')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final MemberModel member = MemberModel.fromJson(userDoc);
        if (mounted) {
          setState(() {
            _isAdmin = member.isAdmin;
          });
        }
      }
    } catch (e) {
      print("Error carregant status d'admin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esdeveniments'),
        actions: [
          // L'historial el mantenim només per a admins?
          // Si vols que el veja tothom, lleva el "if (_isAdmin)"
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.archive),
              tooltip: 'Esdeveniments Passats',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PastEventsPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _firestoreService.getFutureEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error carregant esdeveniments'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No hi ha esdeveniments propers',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final formattedDate = DateFormat(
                'dd/MM/yyyy HH:mm',
                'ca',
              ).format(event.date.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage:
                        (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                        ? NetworkImage(event.imageUrl!)
                        : null,
                    child: (event.imageUrl == null || event.imageUrl!.isEmpty)
                        ? Icon(
                            getIconData(event.iconName, type: 'event'),
                            color: Colors.white,
                          )
                        : null,
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${event.location}\n$formattedDate'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(event: event),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // --- CAMBIO AQUÍ: Botón visible para TODOS ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventPage(),
              fullscreenDialog: true,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
