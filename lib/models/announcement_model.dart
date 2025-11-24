// lib/models/announcement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final Timestamp date;
  final String type; // 'general' o 'birthday'
  final String author;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.type = 'general',
    required this.author,
  });

  factory AnnouncementModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      type: data['type'] ?? 'general',
      author: data['author'] ?? 'Admin',
    );
  }
}
