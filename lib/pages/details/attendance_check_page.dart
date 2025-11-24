// lib/pages/details/attendance_check_page.dart
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceCheckPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const AttendanceCheckPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<AttendanceCheckPage> createState() => _AttendanceCheckPageState();
}

class _AttendanceCheckPageState extends State<AttendanceCheckPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pasar Llista: ${widget.eventTitle}'),
        actions: [
          // Un petit indicador de progrés o info
          StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.events.doc(widget.eventId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final event = EventModel.fromJson(snapshot.data!);
              final total = event.attendees.length + event.manualGuests.length;
              final confirmed =
                  event.confirmedAttendeesUids.length +
                  event.confirmedManualGuests.length;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    "$confirmed / $total",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.events.doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = EventModel.fromJson(snapshot.data!);

          if (event.attendees.isEmpty && event.manualGuests.isEmpty) {
            return const Center(
              child: Text("No hi ha ningú apuntat a l'esdeveniment."),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // SECCIÓ 1: MEMBRES
              if (event.attendees.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Membres de la Filà",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                ...event.attendees.map((attendee) {
                  final uid = attendee['uid'];
                  final mote = attendee['mote'];
                  final fotoUrl = attendee['fotoUrl'];
                  final isConfirmed = event.confirmedAttendeesUids.contains(
                    uid,
                  );

                  return Card(
                    color: isConfirmed
                        ? Colors.green.withAlpha(30)
                        : null, // Fons verd si està confirmat
                    child: SwitchListTile(
                      title: Text(
                        mote,
                        style: TextStyle(
                          fontWeight: isConfirmed
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: const Text("Membre"),
                      secondary: CircleAvatar(
                        backgroundImage: fotoUrl != null
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: fotoUrl == null ? Text(mote[0]) : null,
                      ),
                      value: isConfirmed,
                      activeThumbColor: Colors.green,
                      onChanged: (bool val) {
                        if (val) {
                          _firestoreService.confirmMemberAttendance(
                            event.id,
                            uid,
                          );
                        } else {
                          _firestoreService.unconfirmMemberAttendance(
                            event.id,
                            uid,
                          );
                        }
                      },
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // SECCIÓ 2: CONVIDATS
              if (event.manualGuests.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Convidats Externs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                ...event.manualGuests.map((guest) {
                  final name = guest['name'];
                  final isConfirmed = event.confirmedManualGuests.contains(
                    name,
                  );

                  return Card(
                    color: isConfirmed ? Colors.green.withAlpha(30) : null,
                    child: SwitchListTile(
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isConfirmed
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: const Text("Convidat Manual"),
                      secondary: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      value: isConfirmed,
                      activeThumbColor: Colors.green,
                      onChanged: (bool val) {
                        if (val) {
                          _firestoreService.confirmGuestAttendance(
                            event.id,
                            name,
                          );
                        } else {
                          _firestoreService.unconfirmGuestAttendance(
                            event.id,
                            name,
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}
