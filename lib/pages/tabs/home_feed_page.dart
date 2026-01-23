// lib/pages/tabs/home_feed_page.dart
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/pages/details/event_detail_page.dart';
import 'package:abenceapp/pages/details/voting_detail_page.dart';
import 'package:abenceapp/pages/extras/music_library_page.dart';
import 'package:abenceapp/pages/extras/order_sheets_page.dart'; 
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // CENTRAR TÍTULO
        centerTitle: true,
        title: const Text(
          "Abencerrajes", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
        ),
        
        // --- 2 ICONOS A LA IZQUIERDA (Música y Docs) ---
        leadingWidth: 100, // Damos espacio suficiente para 2 iconos
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 1. Música (Morado)
            IconButton(
              icon: const Icon(Icons.music_note, color: Colors.purple),
              tooltip: 'Música',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicLibraryPage())),
            ),
            // 2. Docs (Azul)
            IconButton(
              icon: const Icon(Icons.folder, color: Colors.blue),
              tooltip: 'Documents',
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pròximament...")),
                );
              },
            ),
          ],
        ),

        // --- 2 ICONOS A LA DERECHA (Encàrrecs y Web) ---
        actions: [
          // 3. Encàrrecs (Naranja)
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.orange),
            tooltip: 'Encàrrecs',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderSheetsPage())),
          ),
          // 4. Web (Verde)
          IconButton(
            icon: const Icon(Icons.language, color: Colors.green),
            tooltip: 'Web',
            onPressed: () {
               // Aquí lógica web futura
            },
          ),
          const SizedBox(width: 8), // Un pequeño margen extra a la derecha
        ],
        
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          
          // NOTA: Hemos quitado los botones del cuerpo porque ya están arriba.

          const SizedBox(height: 10),

          // 2. ANUNCIOS
          _buildAnuncisSection(),
          
          const SizedBox(height: 20),

          // 3. EVENTOS
          const Text(
            "Propers Esdeveniments",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildUpcomingEvents(),

          const SizedBox(height: 25),

          // 4. VOTACIONES
          const Text(
            "Votacions Actives",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildActiveVotings(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- SECCIÓN 2: ANUNCIOS ---
  Widget _buildAnuncisSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('anuncis').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        
        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String? imageUrl = data['imageUrl'];
              final String title = data['title'] ?? 'Avís';
              
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey[200],
                  image: imageUrl != null && imageUrl.isNotEmpty 
                    ? DecorationImage(
                        image: NetworkImage(imageUrl), 
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)
                      )
                    : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 5)]
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- SECCIÓN 3: PRÓXIMOS EVENTOS ---
  Widget _buildUpcomingEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState("No hi ha esdeveniments propers.");
        }

        final now = DateTime.now().subtract(const Duration(hours: 4));
        
        final events = snapshot.data!.docs
            .map((doc) => EventModel.fromJson(doc))
            .where((e) => e.date.toDate().isAfter(now))
            .toList();

        events.sort((a, b) => a.date.compareTo(b.date));
        
        if (events.isEmpty) return _emptyState("No hi ha esdeveniments propers.");

        final displayEvents = events.take(3).toList();

        return Column(
          children: displayEvents.map((event) {
             final dateStr = DateFormat('dd/MM HH:mm').format(event.date.toDate());
             return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getIconData(event.iconName, type: 'event'),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("$dateStr • ${event.location}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event)));
                },
              ),
             );
          }).toList(),
        );
      },
    );
  }

  // --- SECCIÓN 4: VOTACIONES ACTIVAS ---
  Widget _buildActiveVotings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('votings').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState("No hi ha votacions actives.");
        }

        final now = DateTime.now();
        final votings = snapshot.data!.docs
            .map((doc) => VotingModel.fromJson(doc))
            .where((v) => v.endDate.toDate().isAfter(now)) 
            .toList();

        if (votings.isEmpty) return _emptyState("No hi ha votacions actives.");

        return Column(
          children: votings.map((voting) {
            final daysLeft = voting.endDate.toDate().difference(now).inDays;
             return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getIconData(voting.iconName, type: 'voting'),
                    color: Colors.orange[800],
                  ),
                ),
                title: Text(voting.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(daysLeft == 0 ? "Acaba avui" : "Queden $daysLeft dies"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(60, 30),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VotingDetailPage(votingId: voting.id)));
                  },
                  child: const Text("Votar"),
                ),
                onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VotingDetailPage(votingId: voting.id)));
                },
              ),
             );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
    );
  }
}