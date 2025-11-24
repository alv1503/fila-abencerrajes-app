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

  Future<void> _loadAdminStatus() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      final MemberModel member = await _firestoreService.getMemberDetails(
        currentUser.uid,
      );
      if (mounted) {
        setState(() {
          _isAdmin = member.isAdmin;
        });
      }
    } catch (e) {
      print('Error al carregar estat d\'admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esdeveniments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Esdeveniments Passats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PastEventsPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No hi ha esdeveniments programats pròximament.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final List<EventModel> events = snapshot.data!.docs
              .map((doc) => EventModel.fromJson(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final formattedDate = DateFormat(
                'd MMMM, yyyy - HH:mm',
                'ca',
              ).format(event.date.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  // --- CAMBIO: FOTO O ICONA ---
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    // Si hi ha URL, la posem de fons
                    backgroundImage:
                        (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                        ? NetworkImage(event.imageUrl!)
                        : null,
                    // Si NO hi ha URL, posem la icona
                    child: (event.imageUrl == null || event.imageUrl!.isEmpty)
                        ? Icon(
                            getIconData(event.iconName, type: 'event'),
                            color: Colors.white,
                          )
                        : null, // Si hi ha foto, no posem child (perquè es veuria damunt)
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

      floatingActionButton: _isAdmin
          ? FloatingActionButton(
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
            )
          : null,
    );
  }
}
