// lib/services/firestore_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/models/event_model.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Colecciones
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

  // ===========================================================================
  // 1. GESTIÓN DE USUARIOS
  // ===========================================================================

  Future<MemberModel> getMemberDetails(String uid) async {
    DocumentSnapshot doc = await members.doc(uid).get();
    if (!doc.exists) throw Exception("Usuari no trobat");
    return MemberModel.fromJson(doc);
  }

  Stream<QuerySnapshot> getMembersStream() {
    return members.orderBy('nom').snapshots();
  }

  Future<List<String>> getBirthdaysToday() async {
    QuerySnapshot snapshot = await members.get();
    DateTime today = DateTime.now();
    List<String> birthdayNames = [];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['dataNaixement'] != null) {
        DateTime date = (data['dataNaixement'] as Timestamp).toDate();
        if (date.month == today.month && date.day == today.day) {
          String name = (data['mote'] != null && data['mote'] != '')
              ? data['mote']
              : data['nom'];
          birthdayNames.add(name);
        }
      }
    }
    return birthdayNames;
  }

  Future<String?> uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    File file = File(image.path);
    try {
      String fileName =
          'profile_${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('profile_images').child(fileName);
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      await members.doc(_currentUser!.uid).update({'fotoUrl': downloadUrl});
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateMemberProfile({
    required String uid,
    String? mote,
    String? telefon,
    String? adreca,
    String? descripcio,
  }) async {
    Map<String, dynamic> data = {};
    if (mote != null) data['mote'] = mote;
    if (telefon != null) data['telefon'] = telefon;
    if (adreca != null) data['adreca'] = adreca;
    if (descripcio != null) data['descripcio'] = descripcio;

    if (data.isNotEmpty) {
      await members.doc(uid).update(data);
    }
  }

  // --- PRE-REGISTRO ---
  Future<void> createPreApprovedUser({
    required String email,
    required String nom,
    required String cognoms,
  }) async {
    await members.add({
      'email': email.trim().toLowerCase(),
      'nom': nom,
      'cognoms': cognoms,
      'isSetupComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
      'mote': '',
      'dni': '',
      'telefon': '',
      'adreca': '',
      'tipusQuota': 'full',
      'enExcedencia': true,
      'isAdmin': false,
      'linkedChildrenUids': [],
      'dataNaixement': Timestamp.fromDate(DateTime(2000, 1, 1)),
    });
  }

  Future<String?> findPreApprovedUserDocId(String email) async {
    final query = await members
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty ? query.docs.first.id : null;
  }

  Future<void> migrateToRealUser(String tempDocId, String newAuthUid) async {
    final tempDocRef = members.doc(tempDocId);
    final newDocRef = members.doc(newAuthUid);
    final snapshot = await tempDocRef.get();
    if (snapshot.exists) {
      await newDocRef.set(snapshot.data() as Map<String, dynamic>);
      await tempDocRef.delete();
    }
  }

  Future<void> completeUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await members.doc(uid).update({...data, 'isSetupComplete': true});
  }

  // ===========================================================================
  // 2. EVENTOS
  // ===========================================================================

  Stream<List<EventModel>> getFutureEvents() {
    return events
        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('date', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => EventModel.fromFirestore(d)).toList());
  }

  Stream<QuerySnapshot> getUpcomingEventsStream({int limit = 10}) {
    return events
        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('date', descending: false)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot> getPastEventsStream() {
    return events
        .where('date', isLessThan: Timestamp.now())
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> addEvent(
    String title,
    String description,
    String location,
    DateTime date, {
    String? iconName,
    DateTime? endDate,
    String? dressCode,
    List<String>? menuOptions,
    String? imageUrl,
    String? attachedFileUrl,
    String? attachedFileName,
  }) async {
    String creatorMote = '';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) creatorMote = userDoc['mote'] ?? '';
    } catch (_) {}

    await events.add({
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'iconName': iconName ?? 'event',
      'dressCode': dressCode,
      'menuOptions': menuOptions ?? [],
      'imageUrl': imageUrl,
      'attachedFileUrl': attachedFileUrl,
      'attachedFileName': attachedFileName,
      'creatorId': _currentUser?.uid,
      'creatorMote': creatorMote,
      'attendees': [],
      'manualGuests': [],
      'confirmedAttendeesUids': [],
      'confirmedManualGuests': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEvent(
    String id, {
    String? title,
    String? description,
    String? location,
    DateTime? date,
    DateTime? endDate,
    String? iconName,
    String? dressCode,
    List<String>? menuOptions,
    String? imageUrl,
  }) async {
    Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (location != null) data['location'] = location;
    if (date != null) data['date'] = Timestamp.fromDate(date);
    if (endDate != null) data['endDate'] = Timestamp.fromDate(endDate);
    if (iconName != null) data['iconName'] = iconName;
    if (dressCode != null) data['dressCode'] = dressCode;
    if (menuOptions != null) data['menuOptions'] = menuOptions;
    if (imageUrl != null) data['imageUrl'] = imageUrl;

    if (data.isNotEmpty) {
      await events.doc(id).update(data);
    }
  }

  Future<void> deleteEvent(String id) async {
    await events.doc(id).delete();
  }

  Future<void> joinEvent(String eventId, {String? selection}) async {
    Map<String, dynamic> updateData = {
      'attendees': FieldValue.arrayUnion([_currentUser!.uid]),
    };
    if (selection != null) {
      updateData['menuSelections.${_currentUser!.uid}'] = selection;
    }
    await events.doc(eventId).update(updateData);
  }

  Future<void> leaveEvent(String eventId) async {
    await events.doc(eventId).update({
      'attendees': FieldValue.arrayRemove([_currentUser!.uid]),
      'menuSelections.${_currentUser!.uid}': FieldValue.delete(),
    });
  }

  Future<void> joinEventForChild(
    String eventId,
    dynamic child, {
    String? selection,
  }) async {
    String childUid;
    if (child is MemberModel)
      childUid = child.id;
    else if (child is Map)
      childUid = child['uid'] ?? child['id'];
    else
      childUid = child.toString();

    Map<String, dynamic> updateData = {
      'attendees': FieldValue.arrayUnion([childUid]),
    };
    if (selection != null) {
      updateData['menuSelections.$childUid'] = selection;
    }
    await events.doc(eventId).update(updateData);
  }

  Future<void> leaveEventForChild(String eventId, dynamic child) async {
    String childUid;
    if (child is MemberModel)
      childUid = child.id;
    else if (child is Map)
      childUid = child['uid'] ?? child['id'];
    else
      childUid = child.toString();

    await events.doc(eventId).update({
      'attendees': FieldValue.arrayRemove([childUid]),
      'menuSelections.$childUid': FieldValue.delete(),
    });
  }

  // --- SOLUCIÓN: addManualGuest CON selection ---
  Future<void> addManualGuest(
    String eventId,
    String guestName, {
    String? selection,
  }) async {
    Map<String, dynamic> updateData = {
      'manualGuests': FieldValue.arrayUnion([guestName]),
    };
    // Si se pasa una selección de menú, la guardamos.
    // Usamos el nombre del invitado como clave (menuSelections.Pepito)
    if (selection != null) {
      updateData['menuSelections.$guestName'] = selection;
    }
    await events.doc(eventId).update(updateData);
  }

  Future<void> removeManualGuest(String eventId, dynamic guest) async {
    String guestName;
    if (guest is Map)
      guestName = guest['name'] ?? guest['nom'] ?? '';
    else
      guestName = guest.toString();

    if (guestName.isNotEmpty) {
      await events.doc(eventId).update({
        'manualGuests': FieldValue.arrayRemove([guestName]),
        'menuSelections.$guestName':
            FieldValue.delete(), // Limpiamos su menú también
      });
    }
  }

  Future<void> removeAttendee(String eventId, dynamic participant) async {
    String uid;
    if (participant is Map)
      uid = participant['uid'] ?? participant['id'];
    else if (participant is MemberModel)
      uid = participant.id;
    else
      uid = participant.toString();

    await events.doc(eventId).update({
      'attendees': FieldValue.arrayRemove([uid]),
    });
  }

  Future<String?> uploadCoverImage(
    File file, [
    String folder = 'event_covers',
  ]) async {
    try {
      String fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(folder).child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadPdfFile(File file) async {
    try {
      String fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      Reference ref = _storage.ref().child('event_docs').child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ===========================================================================
  // 3. VOTACIONES
  // ===========================================================================
  Stream<QuerySnapshot> getVotingsStream() {
    return votings.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getUpcomingVotingsStream({int limit = 5}) {
    return votings
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot> getRecentlyClosedVotingsStream() {
    return votings
        .where('isActive', isEqualTo: false)
        .orderBy('closedAt', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> addVoting({
    required String title,
    required String description,
    required DateTime endDate,
    required List<String> options,
    String iconName = 'default',
    bool allowMultipleChoices = false,
    String? imageUrl,
    String? attachedFileUrl,
    String? attachedFileName,
  }) async {
    await votings.add({
      'title': title,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'endDate': Timestamp.fromDate(endDate),
      'options': options,
      'iconName': iconName,
      'allowMultipleChoices': allowMultipleChoices,
      'isActive': true,
      'imageUrl': imageUrl,
      'attachedFileUrl': attachedFileUrl,
      'attachedFileName': attachedFileName,
      'creatorId': _currentUser?.uid,
    });
  }

  Future<void> deleteVoting(String id) async {
    await votings.doc(id).delete();
  }

  Stream<DocumentSnapshot> getVotingDocumentStream(String id) {
    return votings.doc(id).snapshots();
  }

  Future<void> castVote(String votingId, Map<String, dynamic> voteData) async {
    await votings
        .doc(votingId)
        .collection('votes')
        .doc(_currentUser!.uid)
        .set(voteData);
  }

  // ===========================================================================
  // 4. DOCUMENTOS
  // ===========================================================================
  Stream<QuerySnapshot> getDocumentsStream() {
    return documents.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addDocument({
    required String title,
    required String category,
    required String pdfUrl,
  }) async {
    await documents.add({
      'title': title,
      'category': category,
      'pdfUrl': pdfUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'uploadedBy': _currentUser?.uid,
    });
  }

  Future<void> deleteDocument(String id, String? fileUrl) async {
    await documents.doc(id).delete();
    if (fileUrl != null) {
      try {
        await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      } catch (_) {}
    }
  }

  // ===========================================================================
  // 5. ORDER SHEETS
  // ===========================================================================
  Stream<QuerySnapshot> getOrderSheetsStream() {
    return orderSheets.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createOrderSheet(
    String title,
    String description,
    DateTime deadline,
  ) async {
    await orderSheets.add({
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'items': [],
    });
  }

  Future<void> deleteOrderSheet(String id) async {
    await orderSheets.doc(id).delete();
  }

  Future<void> toggleOrderSheetStatus(String id, bool currentStatus) async {
    await orderSheets.doc(id).update({'isActive': !currentStatus});
  }

  Future<void> addOrderItem(String sheetId, dynamic item) async {
    await orderSheets.doc(sheetId).update({
      'items': FieldValue.arrayUnion([item]),
    });
  }

  Future<void> removeOrderItem(String sheetId, dynamic item) async {
    await orderSheets.doc(sheetId).update({
      'items': FieldValue.arrayRemove([item]),
    });
  }

  // ===========================================================================
  // 6. RESTO
  // ===========================================================================

  Stream<QuerySnapshot> getTicketsStream() {
    return tickets.orderBy('createdAt', descending: true).snapshots();
  }

  // Acepta Argumentos Posicionales (String, Double) - SOLUCIONADO
  Future<void> addTicket(String concept, double amount) async {
    String payerMote = '';
    try {
      DocumentSnapshot userDoc = await members.doc(_currentUser!.uid).get();
      if (userDoc.exists) payerMote = userDoc['mote'] ?? '';
    } catch (_) {}

    await tickets.add({
      'concept': concept,
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
      'payerId': _currentUser?.uid,
      'payerMote': payerMote,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTicket(String id) async {
    await tickets.doc(id).delete();
  }

  Stream<QuerySnapshot> getAnnouncementsStream() {
    return announcements.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> addAnnouncement(String title, String content) async {
    await announcements.add({
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'authorId': _currentUser?.uid,
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await announcements.doc(id).delete();
  }

  Stream<QuerySnapshot> getMusicLinksStream() {
    return music.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addMusicLink(String url, String title) async {
    await music.add({
      'url': url,
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'addedBy': _currentUser?.uid,
    });
  }

  Future<void> deleteMusicLink(String id) async {
    await music.doc(id).delete();
  }

  Stream<QuerySnapshot> getFeedbackStream() {
    return feedback.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> sendFeedback(String type, String text) async {
    await feedback.add({
      'type': type,
      'text': text,
      'userId': _currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFeedback(String id) async {
    await feedback.doc(id).delete();
  }

  Future<int> cleanOldAttachments() async {
    return 0;
  }

  // Attendance
  Future<void> confirmMemberAttendance(String eventId, String uid) async {
    await events.doc(eventId).update({
      'confirmedAttendeesUids': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> unconfirmMemberAttendance(String eventId, String uid) async {
    await events.doc(eventId).update({
      'confirmedAttendeesUids': FieldValue.arrayRemove([uid]),
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
}
