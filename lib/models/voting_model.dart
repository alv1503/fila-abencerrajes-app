// lib/models/voting_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VotingModel {
  final String id;
  final String title;
  final String description;
  final Timestamp endDate;
  final List<String> options;
  final String creatorMote;
  final String? iconName;
  final bool allowMultipleChoices;
  final String? imageUrl;
  final Map<String, dynamic> results;

  // --- NOU: Document Adjunt Temporal ---
  final String? attachedFileUrl;
  final String? attachedFileName;

  VotingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.endDate,
    required this.options,
    required this.creatorMote,
    required this.results,
    this.iconName,
    this.allowMultipleChoices = false,
    this.imageUrl,
    this.attachedFileUrl,
    this.attachedFileName,
  });

  factory VotingModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return VotingModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      endDate: data['endDate'] ?? Timestamp.now(),
      options: List<String>.from(data['options'] ?? []),
      creatorMote: data['creatorMote'] ?? '',
      results: data['results'] ?? {},
      iconName: data['iconName'],
      allowMultipleChoices: data['allowMultipleChoices'] ?? false,
      imageUrl: data['imageUrl'],
      // Mapeig dels nous camps
      attachedFileUrl: data['attachedFileUrl'],
      attachedFileName: data['attachedFileName'],
    );
  }
}
