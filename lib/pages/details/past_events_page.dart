// lib/pages/details/past_events_page.dart
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/pages/details/event_detail_page.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PastEventsPage extends StatelessWidget {
  const PastEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial d\'Esdeveniments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPastEventsStream(),
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
                  'No hi ha esdeveniments passats.',
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
            padding: const EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final formattedDate = DateFormat(
                'd MMMM, yyyy',
                'ca',
              ).format(event.date.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Colors.grey, // Color gris per indicar passat
                    child: Icon(
                      getIconData(event.iconName, type: 'event'),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$formattedDate - ${event.location}'),
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
    );
  }
}
