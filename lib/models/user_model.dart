// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String nom;
  final String cognoms;
  final String mote;
  final String email;
  final String dni;
  final String telefon;
  final String adreca;
  final Timestamp dataNaixement;
  final String tipusQuota;
  final bool enExcedencia;
  final bool isAdmin;

  // NOU CAMP: Control de configuració inicial
  final bool isSetupComplete;

  final String? fotoUrl;
  final String? descripcio;
  final List<String> linkedChildrenUids;

  MemberModel({
    required this.id,
    required this.nom,
    required this.cognoms,
    required this.mote,
    required this.email,
    required this.dni,
    required this.telefon,
    required this.adreca,
    required this.dataNaixement,
    required this.tipusQuota,
    required this.enExcedencia,
    required this.isAdmin,
    this.isSetupComplete = false,
    this.fotoUrl,
    this.descripcio,
    required this.linkedChildrenUids,
  });

  factory MemberModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MemberModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      cognoms: data['cognoms'] ?? '',
      mote: data['mote'] ?? '',
      email: data['email'] ?? '',
      dni: data['dni'] ?? '',
      telefon: data['telefon'] ?? '',
      adreca: data['adreca'] ?? '',
      dataNaixement: data['dataNaixement'] ?? Timestamp.now(),
      tipusQuota: data['tipusQuota'] ?? 'normal',
      enExcedencia: data['enExcedencia'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      isSetupComplete: data['isSetupComplete'] ?? false,
      fotoUrl: data['fotoUrl'],
      descripcio: data['descripcio'],
      linkedChildrenUids: List<String>.from(data['linkedChildrenUids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'cognoms': cognoms,
      'mote': mote,
      'email': email,
      'dni': dni,
      'telefon': telefon,
      'adreca': adreca,
      'dataNaixement': dataNaixement,
      'tipusQuota': tipusQuota,
      'enExcedencia': enExcedencia,
      'isAdmin': isAdmin,
      'isSetupComplete': isSetupComplete,
      'fotoUrl': fotoUrl,
      'descripcio': descripcio,
      'linkedChildrenUids': linkedChildrenUids,
    };
  }

  // --- LÒGICA D'EDAT (Getters que faltaven) ---

  int get age {
    final DateTime birthDate = dataNaixement.toDate();
    final DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Senior: Major o igual a 21
  bool get isSenior => age >= 21;

  // Jove: Entre 16 i 20 (inclosos)
  bool get isYoung => age >= 16 && age < 21;

  // Infantil: Menor de 16 (AQUÍ ESTAVA L'ERROR)
  bool get isChild => age < 16;
}
