// lib/models/document_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String title;
  final String category; // Ej: "Actas", "Estatutos", "Menús"
  final String pdfUrl;
  final Timestamp uploadedAt;
  final String uploadedBy; // ID del admin que lo subió

  DocumentModel({
    required this.id,
    required this.title,
    required this.category,
    required this.pdfUrl,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory DocumentModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return DocumentModel(
      id: doc.id,
      title: data['title'] ?? 'Sense Títol',
      category: data['category'] ?? 'General',
      pdfUrl: data['pdfUrl'] ?? '',
      uploadedAt: data['uploadedAt'] ?? Timestamp.now(),
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }
}
