// lib/pages/tabs/home_feed_page.dart
import 'package:abenceapp/models/announcement_model.dart';
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/pages/details/event_detail_page.dart';
import 'package:abenceapp/pages/details/voting_detail_page.dart';
import 'package:abenceapp/pages/forms/create_announcement_page.dart';
import 'package:abenceapp/pages/forms/create_event_page.dart'; // NECESSARI PER A CREAR EVENT
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:abenceapp/pages/docs/documents_page.dart';
import 'package:abenceapp/pages/extras/music_library_page.dart';
import 'package:abenceapp/pages/extras/order_sheets_page.dart';
import 'package:abenceapp/pages/extras/tickets_page.dart'; // IMPORT TICKETS

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool _isAdmin = false;
  List<String> _birthdaysToday = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndBirthdays();
  }

  Future<void> _checkAdminAndBirthdays() async {
    try {
      final userDoc = await _firestoreService.getMemberDetails(_currentUserId);
      if (mounted) setState(() => _isAdmin = userDoc.isAdmin);
    } catch (e) {
      /*...*/
    }

    final bdays = await _firestoreService.getBirthdaysToday();
    if (mounted) setState(() => _birthdaysToday = bdays);
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Esborrar Avís"),
        content: const Text("Segur?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí"),
          ),
        ],
      ),
    );
    if (confirm == true) await _firestoreService.deleteAnnouncement(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          // 1. AVISOS (Només Admin)
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.campaign, color: Colors.orangeAccent),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateAnnouncementPage(),
                ),
              ),
            ),

          // 2. CREAR EVENT (ARA PER A TOTS - CAMBI 1)
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.blueAccent,
            ), // Icona destacada
            tooltip: 'Crear Event',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateEventPage()),
            ),
          ),

          // 3. TICKETS / PAGAMENTS (NOU - CAMBI 2)
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.green),
            tooltip: 'Tickets i Comptes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TicketsPage()),
            ),
          ),

          // 4. ALTRES
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderSheetsListPage(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.music_note),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MusicLibraryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DocumentsPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBulletinBoard(),
            const SizedBox(height: 24),
            const Text(
              'Pròxims Esdeveniments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildEventsList(),
            const SizedBox(height: 30),
            const Text(
              'Votacions Actives',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildVotingsList(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  // (COPIA ELS MATEIXOS DE LA VERSIÓ ANTERIOR: _buildBulletinBoard, _buildEventsList, ETC.)
  // Si els necessites de nou, demana-m'ho, però són exactament els mateixos de l'últim missatge.

  Widget _buildBulletinBoard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAnnouncementsStream(),
      builder: (context, snapshot) {
        List<Widget> cards = [];
        if (_birthdaysToday.isNotEmpty) cards.add(_buildBirthdayCard());
        if (snapshot.hasData) {
          final announcements = snapshot.data!.docs
              .map((doc) => AnnouncementModel.fromJson(doc))
              .toList();
          for (var notice in announcements) {
            cards.add(_buildNoticeCard(notice));
          }
        }
        if (cards.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taulell d\'Anuncis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: cards,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBirthdayCard() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.deepPurple],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cake, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Per molts anys!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                _birthdaysToday.join(", "),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "🎂 La Filà us felicita",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(AnnouncementModel notice) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notice.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isAdmin)
                GestureDetector(
                  onTap: () => _deleteAnnouncement(notice.id),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
            ],
          ),
          const Divider(height: 12),
          Expanded(
            child: Text(
              notice.content,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM').format(notice.date.toDate()),
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUpcomingEventsStream(limit: 4),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyCard("No hi ha esdeveniments.");
          }
          final events = snapshot.data!.docs
              .map((doc) => EventModel.fromJson(doc))
              .toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildImageCard(
                context,
                title: event.title,
                date: event.date.toDate(),
                imageUrl: event.imageUrl,
                iconName: event.iconName,
                type: 'event',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailPage(event: event),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVotingsList() {
    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getUpcomingVotingsStream(limit: 4),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyCard("No hi ha votacions actives.");
          }
          final votings = snapshot.data!.docs
              .map((doc) => VotingModel.fromJson(doc))
              .toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: votings.length,
            itemBuilder: (context, index) {
              final voting = votings[index];
              return _buildImageCard(
                context,
                title: voting.title,
                date: voting.endDate.toDate(),
                imageUrl: voting.imageUrl,
                iconName: voting.iconName,
                type: 'voting',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VotingDetailPage(votingId: voting.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context, {
    required String title,
    required DateTime date,
    String? imageUrl,
    String? iconName,
    required String type,
    required VoidCallback onTap,
  }) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                )
              : null,
          border: !hasImage ? Border.all(color: Colors.grey[800]!) : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  type == 'event' ? Icons.calendar_today : Icons.how_to_vote,
                  size: 14,
                  color: hasImage
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat(
                    type == 'event' ? 'dd MMM - HH:mm' : 'Tanca: dd MMM',
                    'ca',
                  ).format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasImage
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: hasImage
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
