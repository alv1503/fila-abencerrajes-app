// lib/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final Timestamp date;
  final Timestamp? endDate;
  final String? dressCode;
  final List<String> menuOptions;
  final String creatorId;
  final String creatorMote;
  final List<dynamic> attendees;
  final List<dynamic> manualGuests;
  final List<String> confirmedAttendeesUids;
  final List<String> confirmedManualGuests;
  final String? iconName;
  final String? imageUrl;

  // --- Document Adjunt Temporal ---
  final String? attachedFileUrl;
  final String? attachedFileName;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    this.endDate,
    this.dressCode,
    this.menuOptions = const [],
    required this.creatorId,
    required this.creatorMote,
    required this.attendees,
    this.manualGuests = const [],
    this.confirmedAttendeesUids = const [],
    this.confirmedManualGuests = const [],
    this.iconName,
    this.imageUrl,
    this.attachedFileUrl,
    this.attachedFileName,
  });

  // Constructor existent (usat en algunes parts antigues)
  factory EventModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      endDate: data['endDate'],
      dressCode: data['dressCode'],
      menuOptions: List<String>.from(data['menuOptions'] ?? []),
      creatorId: data['creatorId'] ?? '',
      creatorMote: data['creatorMote'] ?? '',
      attendees: data['attendees'] ?? [],
      manualGuests: data['manualGuests'] ?? [],
      confirmedAttendeesUids: List<String>.from(
        data['confirmedAttendeesUids'] ?? [],
      ),
      confirmedManualGuests: List<String>.from(
        data['confirmedManualGuests'] ?? [],
      ),
      iconName: data['iconName'],
      imageUrl: data['imageUrl'],
      attachedFileUrl: data['attachedFileUrl'],
      attachedFileName: data['attachedFileName'],
    );
  }

  // --- NOU CONSTRUCTOR: fromFirestore ---
  // Aquest és el que crida el nou codi de FirestoreService.
  // Simplement reutilitza la lògica de fromJson per a no duplicar codi.
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    return EventModel.fromJson(doc);
  }
}
