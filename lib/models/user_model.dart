// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Defineix l'estructura de dades per a un usuari/membre.
class MemberModel {
  // Propietats existents
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

  // Propietats opcionals existents
  final String? fotoUrl;
  final String? descripcio;

  // --- 1. NOU CAMP: Vinculació Familiar ---
  /// Llista d'IDs dels membres "Niño" vinculats a aquest usuari (si és Senior).
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
    this.fotoUrl,
    this.descripcio,
    // Inicialitzem la llista buida per defecte al constructor
    this.linkedChildrenUids = const [],
  });

  /// Constructor de fàbrica des de Firestore
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
      fotoUrl: data['fotoUrl'],
      descripcio: data['descripcio'],

      // Llegim la llista de fills (si existeix) i assegurem el tipus.
      linkedChildrenUids: List<String>.from(data['linkedChildrenUids'] ?? []),
    );
  }

  // --- 2. LÒGICA D'EDAT I ROLS ---

  /// Calcula l'edat actual basada en la data de naixement.
  int get age {
    final DateTime birthDate = dataNaixement.toDate();
    final DateTime today = DateTime.now();

    int age = today.year - birthDate.year;

    // Ajustem si encara no ha sigut el seu aniversari enguany
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// És Senior? (Major o igual a 21 anys)
  /// Té tots els privilegis: votar, anar a actes, gestionar fills.
  bool get isSenior => age >= 21;

  /// És Jove? (De 16 a 20 anys)
  /// Pot anar a actes però NO pot votar.
  bool get isYoung => age >= 16 && age < 21;

  /// És Nen? (Menor de 16 anys)
  /// No té accions pròpies, depèn d'un Senior.
  bool get isChild => age < 16;

  /// Helper per a obtindre el nom del rol en text (per a mostrar al perfil).
  String get roleName {
    if (isSenior) return 'Membre Senior';
    if (isYoung) return 'Membre Jove';
    return 'Infantil';
  }
}
