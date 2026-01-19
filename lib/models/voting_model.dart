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

  // Documents adjunts
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
    // 1. Obtenim les dades protegint-nos si el document és null
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    // 2. BLINDATGE DE RESULTATS (Aquí sol estar l'error en vots antics)
    // Comprovem si 'results' és realment un Mapa. Si és una Llista o null, posem {}.
    Map<String, dynamic> safeResults = {};
    var rawResults = data['results'];

    if (rawResults is Map) {
      try {
        safeResults = Map<String, dynamic>.from(rawResults);
      } catch (e) {
        // Si falla la conversió, deixem el mapa buit
        safeResults = {};
      }
    }

    return VotingModel(
      id: doc.id,
      title: data['title'] ?? 'Votació sense títol',
      description: data['description'] ?? '',
      endDate: data['endDate'] ?? Timestamp.now(),
      options: List<String>.from(data['options'] ?? []),
      creatorMote: data['creatorMote'] ?? 'Anònim',
      results: safeResults, // <--- Usem la versió segura
      iconName: data['iconName'],
      allowMultipleChoices: data['allowMultipleChoices'] ?? false,
      imageUrl: data['imageUrl'],
      attachedFileUrl: data['attachedFileUrl'],
      attachedFileName: data['attachedFileName'],
    );
  }
}
