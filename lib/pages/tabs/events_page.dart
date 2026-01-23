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
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('membres')
          .doc(currentUser.uid)
          .get();
          
      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isAdmin = data['isAdmin'] == true;
        });
      }
    } catch (e) {
      debugPrint("Error loading admin status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pròxims Esdeveniments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getEventsStream(),
        builder: (context, snapshot) {
          // 1. Errores de conexión o Firestore
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error carregant esdeveniments: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hi ha esdeveniments programats.'));
          }

          // 2. Filtrado Lógico (Cliente)
          // Mostramos eventos futuros + los que han empezado hace menos de 4 horas (para que no desaparezcan durante el evento)
          final now = DateTime.now().subtract(const Duration(hours: 4));

          final List<EventModel> events = snapshot.data!.docs
              .map((doc) => EventModel.fromJson(doc))
              .where((event) => event.date.toDate().isAfter(now))
              .toList();

          // 3. Ordenación (El más cercano primero)
          events.sort((a, b) => a.date.compareTo(b.date));

          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No hi ha esdeveniments propers.\nMira l\'historial per veure els passats.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // 4. Lista Visual
          return ListView.builder(
            itemCount: events.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final event = events[index];
              final String formattedDate = DateFormat(
                'd MMMM - HH:mm',
                'ca',
              ).format(event.date.toDate());

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      getIconData(event.iconName, type: 'event'),
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(formattedDate, style: TextStyle(color: Colors.grey[800])),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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

      // Botón visible para todos (o solo admin, según prefieras)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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