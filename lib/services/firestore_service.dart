// lib/services/firestore_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:abenceapp/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final CollectionReference members = FirebaseFirestore.instance.collection(
    'membres',
  );
  final CollectionReference events = FirebaseFirestore.instance.collection(
    'events',
  );
  final CollectionReference votings = FirebaseFirestore.instance.collection(
    'votacions',
  );
  final CollectionReference documents = FirebaseFirestore.instance.collection(
    'documents',
  );
  final CollectionReference feedback = FirebaseFirestore.instance.collection(
    'feedback',
  );
  final CollectionReference announcements = FirebaseFirestore.instance
      .collection('announcements');
  final CollectionReference music = FirebaseFirestore.instance.collection(
    'music_links',
  );

  final CollectionReference orderSheets = FirebaseFirestore.instance.collection(
    'order_sheets',
  );

  final CollectionReference tickets = FirebaseFirestore.instance.collection(
    'tickets',
  );

  User? get _currentUser => _auth.currentUser;

  // --- Funcions de Membres (Sense canvis) ---
  Future<MemberModel> getMemberDetails(String uid) async {
    try {
      final DocumentSnapshot doc = await members.doc(uid).get();
      return MemberModel.fromJson(doc);
    } catch (e) {
      print(e.toString());
      throw Exception('Error al carregar les dades del membre');
    }
  }

  Stream<QuerySnapshot> getMembersStream() {
    // Ordenem alfabèticament per 'mote' de la A a la Z
    return members.orderBy('mote', descending: false).snapshots();
  }

  Future<void> updateMemberField(String uid, String field, dynamic value) {
    return members.doc(uid).update({field: value});
  }

  Future<void> updateMemberProfile({
    required String uid,
    required String mote,
    required String telefon,
    required String adreca,
    required String? descripcio,
  }) {
    return members.doc(uid).update({
      'mote': mote,
      'telefon': telefon,
      'adreca': adreca,
      'descripcio': descripcio,
    });
  }

  Future<String?> uploadProfileImage() async {
    if (_currentUser == null) throw Exception("Usuari no autenticat");
    final String userId = _currentUser!.uid;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return null;
      final String filePath = 'profile_pics/$userId/profile_pic.jpg';
      final Reference storageRef = _storage.ref(filePath);
      await storageRef.putFile(File(image.path));
      final String downloadURL = await storageRef.getDownloadURL();
      await updateMemberField(userId, 'fotoUrl', downloadURL);
      return downloadURL;
    } catch (e) {
      print("Error al pujar la imatge: $e");
      throw Exception("Error al pujar la imatge");
    }
  }

  // --- NOU: Pujar Imatge Genèrica (per a portades) ---
  Future<String?> uploadCoverImage(File imageFile, String folderName) async {
    if (_currentUser == null) return null;
    try {
      // Creem un nom únic basat en el temps
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref('$folderName/$fileName');

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error pujant imatge: $e");
      return null;
    }
  }

  // --- Funcions d'Esdeveniments ---

  Stream<QuerySnapshot> getEventsStream() {
    final now = Timestamp.now();
    return events
        .where('date', isGreaterThanOrEqualTo: now)
        .orderBy('date', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getUpcomingEventsStream({int limit = 4}) {
    final now = Timestamp.now();
    return events
        .where('date', isGreaterThanOrEqualTo: now)
        .orderBy('date', descending: false)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot> getPastEventsStream() {
    final now = Timestamp.now();
    return events
        .where('date', isLessThan: now)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> deleteEvent(String eventId) async {
    if (_currentUser == null) return;
    await events.doc(eventId).delete();
  }

  // AFEGIR EVENT (AMB ADJUNT)
  Future<void> addEvent(
    String title,
    String description,
    String location,
    DateTime date, {
    required String? iconName,
    DateTime? endDate,
    String? dressCode,
    List<String>? menuOptions,
    String? imageUrl,
    // Nous paràmetres opcionals
    String? attachedFileUrl,
    String? attachedFileName,
  }) async {
    if (_currentUser == null) throw Exception('Usuari no autenticat');

    String creatorMote = 'Admin';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        creatorMote =
            (userDoc.data() as Map<String, dynamic>)['mote'] ?? 'Admin';
      }
    } catch (e) {
      /*...*/
    }

    await events.add({
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'dressCode': dressCode,
      'menuOptions': menuOptions ?? [],
      'imageUrl': imageUrl,
      'attachedFileUrl': attachedFileUrl, // Guardem URL PDF
      'attachedFileName': attachedFileName, // Guardem Nom PDF
      'creatorId': _currentUser!.uid,
      'creatorMote': creatorMote,
      'attendees': [],
      'manualGuests': [],
      'confirmedAttendeesUids': [],
      'confirmedManualGuests': [],
      'iconName': iconName,
    });
  }

  // ACTUALITZAR EVENT (AMB ADJUNT)
  Future<void> updateEvent(
    String eventId, {
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String? iconName,
    DateTime? endDate,
    String? dressCode,
    List<String>? menuOptions,
    String? imageUrl,
    String? attachedFileUrl,
    String? attachedFileName,
  }) async {
    if (_currentUser == null) return;

    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'dressCode': dressCode,
      'iconName': iconName,
    };

    if (menuOptions != null) updateData['menuOptions'] = menuOptions;
    if (imageUrl != null) updateData['imageUrl'] = imageUrl;

    // Actualitzem fitxer només si s'envia (si és null, no esborrem l'anterior excepte si ho gestionem explícitament)
    if (attachedFileUrl != null) {
      updateData['attachedFileUrl'] = attachedFileUrl;
      updateData['attachedFileName'] = attachedFileName;
    }

    await events.doc(eventId).update(updateData);
  }

  // --- JOIN / LEAVE (MILLORAT) ---

  // Apuntar-se (amb opció de menú)
  // Si ja estava apuntat, això actualitzarà la seua entrada (esborra l'antiga i posa la nova)
  Future<void> joinEvent(String eventId, {String? selection}) async {
    if (_currentUser == null) return;

    // 1. Primer ens assegurem d'esborrar qualsevol registre previ d'aquest usuari
    // per a evitar duplicats o dades antigues.
    await leaveEvent(eventId);

    // 2. Obtenim dades actuals
    DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
    final data = userDoc.data() as Map<String, dynamic>;

    final Map<String, dynamic> attendeeMap = {
      'uid': _currentUser!.uid,
      'mote': data['mote'] ?? 'Anònim',
      'fotoUrl': data['fotoUrl'],
      'selection': selection, // Guardem l'elecció (ex: "Pollastre")
    };

    await events.doc(eventId).update({
      'attendees': FieldValue.arrayUnion([attendeeMap]),
    });
  }

  // Esborrar-se (Lògica robusta: filtra per UID)
  Future<void> leaveEvent(String eventId) async {
    if (_currentUser == null) return;
    final uidToRemove = _currentUser!.uid;

    // 1. Llegim el document
    final doc = await events.doc(eventId).get();
    if (!doc.exists) return;

    // 2. Filtrem la llista localment
    List<dynamic> currentAttendees =
        (doc.data() as Map<String, dynamic>)['attendees'] ?? [];
    List<dynamic> updatedAttendees = currentAttendees
        .where((a) => a['uid'] != uidToRemove)
        .toList();

    // 3. Guardem la llista neta
    await events.doc(eventId).update({'attendees': updatedAttendees});
  }

  // Apuntar Fill (amb opció de menú)
  Future<void> joinEventForChild(
    String eventId,
    MemberModel child, {
    String? selection,
  }) async {
    if (_currentUser == null) return;

    await leaveEventForChild(eventId, child); // Neteja prèvia

    final Map<String, dynamic> attendeeMap = {
      'uid': child.id,
      'mote': child.mote,
      'fotoUrl': child.fotoUrl,
      'selection': selection, // Elecció del fill
    };

    await events.doc(eventId).update({
      'attendees': FieldValue.arrayUnion([attendeeMap]),
    });
  }

  // Esborrar Fill (Lògica robusta)
  Future<void> leaveEventForChild(String eventId, MemberModel child) async {
    if (_currentUser == null) return;
    final uidToRemove = child.id;

    final doc = await events.doc(eventId).get();
    if (!doc.exists) return;

    List<dynamic> currentAttendees =
        (doc.data() as Map<String, dynamic>)['attendees'] ?? [];
    List<dynamic> updatedAttendees = currentAttendees
        .where((a) => a['uid'] != uidToRemove)
        .toList();

    await events.doc(eventId).update({'attendees': updatedAttendees});
  }

  // --- GESTIÓ DE PARTICIPANTS (ADMIN) ---

  // Eliminar assistent (Lògica robusta per UID)
  Future<void> removeAttendee(String eventId, String attendeeUid) async {
    final doc = await events.doc(eventId).get();
    if (!doc.exists) return;

    List<dynamic> currentAttendees =
        (doc.data() as Map<String, dynamic>)['attendees'] ?? [];
    List<dynamic> updatedAttendees = currentAttendees
        .where((a) => a['uid'] != attendeeUid)
        .toList();

    await events.doc(eventId).update({'attendees': updatedAttendees});
  }

  Future<void> addManualGuest(
    String eventId,
    String guestName, {
    String? selection,
  }) async {
    if (_currentUser == null) return;

    String hostMote = 'Membre';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        hostMote = (userDoc.data() as Map<String, dynamic>)['mote'] ?? 'Membre';
      }
    } catch (e) {
      /*...*/
    }

    final Map<String, dynamic> guestMap = {
      'name': guestName,
      'addedBy': _currentUser!.uid,
      'addedByMote': hostMote,
      'addedAt': Timestamp.now(),
      'selection': selection, // Elecció del convidat
    };

    await events.doc(eventId).update({
      'manualGuests': FieldValue.arrayUnion([guestMap]),
    });
  }

  Future<void> removeManualGuest(
    String eventId,
    Map<String, dynamic> guestMap,
  ) async {
    // Per als convidats manuals, com que no tenen UID fix, sí que usem arrayRemove
    // amb el mapa exacte, ja que és l'única manera d'identificar-los unívocament.
    await events.doc(eventId).update({
      'manualGuests': FieldValue.arrayRemove([guestMap]),
    });
  }

  // --- CONTROL D'ASSISTÈNCIA ---
  Future<void> confirmMemberAttendance(String eventId, String memberUid) async {
    await events.doc(eventId).update({
      'confirmedAttendeesUids': FieldValue.arrayUnion([memberUid]),
    });
  }

  Future<void> unconfirmMemberAttendance(
    String eventId,
    String memberUid,
  ) async {
    await events.doc(eventId).update({
      'confirmedAttendeesUids': FieldValue.arrayRemove([memberUid]),
    });
  }

  Future<void> confirmGuestAttendance(String eventId, String guestName) async {
    await events.doc(eventId).update({
      'confirmedManualGuests': FieldValue.arrayUnion([guestName]),
    });
  }

  Future<void> unconfirmGuestAttendance(
    String eventId,
    String guestName,
  ) async {
    await events.doc(eventId).update({
      'confirmedManualGuests': FieldValue.arrayRemove([guestName]),
    });
  }

  // --- Funcions de Votació (Sense canvis) ---
  Stream<QuerySnapshot> getVotingsStream() {
    final now = Timestamp.now();
    return votings
        .where('endDate', isGreaterThanOrEqualTo: now)
        .orderBy('endDate', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getUpcomingVotingsStream({int limit = 2}) {
    final now = Timestamp.now();
    return votings
        .where('endDate', isGreaterThanOrEqualTo: now)
        .orderBy('endDate', descending: false)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot> getRecentlyClosedVotingsStream() {
    final now = Timestamp.now();
    final twoDaysAgo = Timestamp.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch - (48 * 60 * 60 * 1000),
    );
    return votings
        .where('endDate', isLessThan: now)
        .where('endDate', isGreaterThan: twoDaysAgo)
        .orderBy('endDate', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getVotingDocumentStream(String votingId) {
    return votings.doc(votingId).snapshots();
  }

  Future<void> deleteVoting(String votingId) async {
    if (_currentUser == null) return;
    await votings.doc(votingId).delete();
  }

  // 1. CAST VOTE ACTUALITZAT (Accepta dynamic per a suportar String o List)
  Future<void> castVote(String votingId, dynamic selectedOption) async {
    if (_currentUser == null) throw Exception("Usuari no autenticat");
    final String userId = _currentUser!.uid;
    try {
      final DocumentReference votingRef = votings.doc(votingId);
      // Guardem l'elecció (pot ser String "A" o Llista ["A", "B"])
      await votingRef.update({'results.$userId': selectedOption});
    } catch (e) {
      print("Error en emetre el vot: $e");
      throw Exception("Error en emetre el vot");
    }
  }

  // AFEGIR VOTACIÓ (AMB ADJUNT)
  Future<void> addVoting({
    required String title,
    required String description,
    required DateTime endDate,
    required List<String> options,
    required String? iconName,
    bool allowMultipleChoices = false,
    String? imageUrl,
    String? attachedFileUrl,
    String? attachedFileName,
  }) async {
    if (_currentUser == null) throw Exception('Usuari no autenticat');

    String creatorMote = 'Admin';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        creatorMote =
            (userDoc.data() as Map<String, dynamic>)['mote'] ?? 'Admin';
      }
    } catch (e) {
      /*...*/
    }

    await votings.add({
      'title': title,
      'description': description,
      'endDate': Timestamp.fromDate(endDate),
      'options': options,
      'creatorMote': creatorMote,
      'results': {},
      'iconName': iconName,
      'allowMultipleChoices': allowMultipleChoices,
      'imageUrl': imageUrl,
      'attachedFileUrl': attachedFileUrl,
      'attachedFileName': attachedFileName,
    });
  }

  // --- GESTIÓ DE DOCUMENTOS (PDFs) ---

  /// Pujar el fitxer PDF al Storage i retornar la URL
  Future<String?> uploadPdfFile(File file) async {
    if (_currentUser == null) return null;
    try {
      // Nom únic: timestamp_nomoriginal.pdf
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_doc.pdf';
      final Reference storageRef = _storage.ref('documents/$fileName');

      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error pujant PDF: $e");
      return null;
    }
  }

  /// Crear el registre del document a Firestore
  Future<void> addDocument({
    required String title,
    required String category,
    required String pdfUrl,
  }) async {
    if (_currentUser == null) throw Exception('Usuari no autenticat');

    await documents.add({
      'title': title,
      'category': category,
      'pdfUrl': pdfUrl,
      'uploadedAt': Timestamp.now(),
      'uploadedBy': _currentUser!.uid,
    });
  }

  /// Obtenir tots els documents ordenats per data
  Stream<QuerySnapshot> getDocumentsStream() {
    return documents.orderBy('uploadedAt', descending: true).snapshots();
  }

  /// Obtenir documents filtrats per categoria (Opcional)
  Stream<QuerySnapshot> getDocumentsByCategoryStream(String category) {
    return documents
        .where('category', isEqualTo: category)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// Esborrar document
  Future<void> deleteDocument(String docId, String pdfUrl) async {
    // 1. Esborrar el registre de Firestore
    await documents.doc(docId).delete();

    // 2. Intentar esborrar el fitxer de Storage (neteja)
    try {
      final Reference storageRef = _storage.refFromURL(pdfUrl);
      await storageRef.delete();
    } catch (e) {
      print("Error esborrant fitxer d'Storage (potser ja no existeix): $e");
    }
  }

  // --- BÚSTIA DE SOPORT / FEEDBACK ---

  /// Enviar un missatge al desenvolupador
  Future<void> sendFeedback(String subject, String message) async {
    if (_currentUser == null) return;

    // Intentem obtindre el mote de l'usuari per a saber qui és
    String userMote = 'Usuari';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        userMote = (userDoc.data() as Map<String, dynamic>)['mote'] ?? 'Usuari';
      }
    } catch (e) {
      print("Error obtenint mote per feedback: $e");
    }

    await feedback.add({
      'uid': _currentUser!.uid,
      'mote': userMote,
      'subject': subject,
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'version': '1.0.0',
    });
  }

  /// Llegir tots els missatges (Admin) - AQUESTA ÉS LA QUE ET FALTA
  Stream<QuerySnapshot> getFeedbackStream() {
    return feedback.orderBy('timestamp', descending: true).snapshots();
  }

  /// Esborrar missatge (Admin)
  Future<void> deleteFeedback(String id) async {
    await feedback.doc(id).delete();
  }

  // --- TABLÓN DE ANUNCIOS Y CUMPLEAÑOS ---

  // 1. Obtener anuncios GENERALES (Base de datos)
  Stream<QuerySnapshot> getAnnouncementsStream() {
    return announcements.orderBy('date', descending: true).snapshots();
  }

  // 2. Añadir anuncio manual
  Future<void> addAnnouncement(String title, String content) async {
    if (_currentUser == null) return;
    await announcements.add({
      'title': title,
      'content': content,
      'date': Timestamp.now(),
      'type': 'general',
      'author': 'La Junta',
    });
  }

  // 3. Borrar anuncio
  Future<void> deleteAnnouncement(String id) async {
    await announcements.doc(id).delete();
  }

  // 4. CALCULAR CUMPLEAÑOS DE HOY
  // Retorna una lista de nombres de los que cumplen años hoy.
  Future<List<String>> getBirthdaysToday() async {
    List<String> birthdayNames = [];
    try {
      // Obtenemos todos los miembros (para una filà de <500 personas esto es rápido)
      final snapshot = await members.get();
      final DateTime today = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['dataNaixement'] != null) {
          DateTime birthDate = (data['dataNaixement'] as Timestamp).toDate();

          // Comprobamos si coincide día y mes
          if (birthDate.day == today.day && birthDate.month == today.month) {
            birthdayNames.add(data['mote'] ?? data['nom']);
          }
        }
      }
    } catch (e) {
      print("Error calculando cumpleaños: $e");
    }
    return birthdayNames;
  }

  // --- GARBAGE COLLECTOR (LIMPIEZA AUTOMÁTICA) ---

  /// Busca eventos i votacions de fa més de 30 dies i esborra els seus adjunts
  /// Retorna el nombre de fitxers esborrats.
  Future<int> cleanOldAttachments() async {
    if (_currentUser == null) return 0;

    int deletedCount = 0;
    // Data límit: Fa 30 dies
    final DateTime threshold = DateTime.now().subtract(
      const Duration(days: 30),
    );
    final Timestamp thresholdTs = Timestamp.fromDate(threshold);

    try {
      // 1. NETEJA D'ESDEVENIMENTS
      // Busquem events on la data siga anterior al límit
      final eventSnaps = await events
          .where('date', isLessThan: thresholdTs)
          .get();

      for (var doc in eventSnaps.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? fileUrl = data['attachedFileUrl'];

        if (fileUrl != null && fileUrl.isNotEmpty) {
          // Intentem esborrar del Storage
          try {
            await _storage.refFromURL(fileUrl).delete();
            deletedCount++;
            print("Arxiu d'esdeveniment esborrat: ${doc.id}");
          } catch (e) {
            print("L'arxiu ja no existia o error: $e");
          }
          // Actualitzem el document per a llevar la referència (encara que falli l'esborrat, netegem la DB)
          await doc.reference.update({
            'attachedFileUrl': null,
            'attachedFileName': null,
          });
        }
      }

      // 2. NETEJA DE VOTACIONS
      // Busquem votacions que van acabar fa més de 30 dies
      final votingSnaps = await votings
          .where('endDate', isLessThan: thresholdTs)
          .get();

      for (var doc in votingSnaps.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? fileUrl = data['attachedFileUrl'];

        if (fileUrl != null && fileUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(fileUrl).delete();
            deletedCount++;
            print("Arxiu de votació esborrat: ${doc.id}");
          } catch (e) {
            print("L'arxiu ja no existia o error: $e");
          }
          await doc.reference.update({
            'attachedFileUrl': null,
            'attachedFileName': null,
          });
        }
      }
    } catch (e) {
      print("Error general en Garbage Collector: $e");
      rethrow;
    }

    return deletedCount;
  }

  // --- MÚSICA (ENLLAÇOS) ---

  // 1. Obtindre llista de música
  Stream<QuerySnapshot> getMusicLinksStream() {
    // Ordenem per títol
    return music.orderBy('title').snapshots();
  }

  // 2. Afegir enllaç (Admin)
  Future<void> addMusicLink(String title, String url) async {
    if (_currentUser == null) return;
    await music.add({
      'title': title,
      'url': url,
      'addedBy': _currentUser!.uid,
      'timestamp': Timestamp.now(),
    });
  }

  // 3. Esborrar enllaç (Admin)
  Future<void> deleteMusicLink(String id) async {
    await music.doc(id).delete();
  }

  // --- HOJAS DE PEDIDOS (ENCÀRRECS) ---

  // 1. Obtindre llista de fulls de comandes (Actives primer)
  Stream<QuerySnapshot> getOrderSheetsStream() {
    return orderSheets.orderBy('deadline', descending: false).snapshots();
  }

  // 2. Crear Full de Comanda (Admin)
  Future<void> createOrderSheet(
    String title,
    String description,
    DateTime deadline,
  ) async {
    if (_currentUser == null) return;
    await orderSheets.add({
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'isActive': true,
      'items': [], // Llista buida inicialment
      'createdAt': Timestamp.now(),
    });
  }

  // 3. Afegir una línia de comanda (Usuari)
  Future<void> addOrderItem(String sheetId, String orderText) async {
    if (_currentUser == null) return;

    // Obtenim el mote de l'usuari
    String userMote = 'Usuari';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        userMote = (userDoc.data() as Map<String, dynamic>)['mote'];
      }
    } catch (e) {
      /*...*/
    }

    final newItem = {
      'uid': _currentUser!.uid,
      'mote': userMote,
      'orderText': orderText,
      'timestamp': Timestamp.now(),
    };

    // Usem arrayUnion per afegir a la llista sense sobrescriure
    await orderSheets.doc(sheetId).update({
      'items': FieldValue.arrayUnion([newItem]),
    });
  }

  // 4. Esborrar una línia de comanda (Usuari o Admin)
  // Necessitem passar l'objecte exacte per a que arrayRemove funcione
  Future<void> removeOrderItem(
    String sheetId,
    Map<String, dynamic> itemData,
  ) async {
    await orderSheets.doc(sheetId).update({
      'items': FieldValue.arrayRemove([itemData]),
    });
  }

  // 5. Tancar/Obrir Full (Admin)
  Future<void> toggleOrderSheetStatus(String sheetId, bool isActive) async {
    await orderSheets.doc(sheetId).update({'isActive': isActive});
  }

  // 6. Esborrar Full complet (Admin)
  Future<void> deleteOrderSheet(String sheetId) async {
    await orderSheets.doc(sheetId).delete();
  }

  // --- GESTOR DE TICKETS (PAGAMENTS) ---

  // 1. Obtindre llista de tickets (els més nous primer)
  Stream<QuerySnapshot> getTicketsStream() {
    return tickets.orderBy('date', descending: true).snapshots();
  }

  // 2. Afegir Ticket
  Future<void> addTicket(String concept, double amount) async {
    if (_currentUser == null) return;

    String userMote = 'Usuari';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        userMote = (userDoc.data() as Map<String, dynamic>)['mote'];
      }
    } catch (e) {
      /*...*/
    }

    await tickets.add({
      'payerUid': _currentUser!.uid,
      'payerMote': userMote,
      'concept': concept,
      'amount': amount,
      'date': Timestamp.now(),
    });
  }

  // 3. Esborrar Ticket (Només el propietari o l'admin)
  Future<void> deleteTicket(String id) async {
    await tickets.doc(id).delete();
  }
}
