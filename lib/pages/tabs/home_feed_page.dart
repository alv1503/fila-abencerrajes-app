// lib/pages/tabs/home_feed_page.dart
import 'package:abenceapp/models/announcement_model.dart';
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/pages/details/event_detail_page.dart';
import 'package:abenceapp/pages/details/voting_detail_page.dart';
import 'package:abenceapp/pages/forms/create_announcement_page.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:abenceapp/pages/docs/documents_page.dart';
import 'package:abenceapp/pages/extras/music_library_page.dart';
import 'package:abenceapp/pages/extras/tickets_page.dart';
import 'package:abenceapp/pages/extras/order_sheets_page.dart'; // <--- ESTE ES EL IMPORTANTE

// --- IMPORTS DE ACTUALIZACIONES ---
import 'package:upgrader/upgrader.dart';

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final member = await _firestoreService.getMemberDetails(user.uid);
        if (mounted) {
          setState(() {
            _isAdmin = member.isAdmin;
            _userName = member.mote.isNotEmpty ? member.mote : member.nom;
          });
        }
      } catch (e) {
        debugPrint('Error carregant usuari: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UpgradeAlert(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),

                // 1. ANUNCIS
                _buildAnnouncementsSection(),
                const SizedBox(height: 20),

                // 2. PRÒXIMS ESDEVENIMENTS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Pròxims Esdeveniments",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          DefaultTabController.of(context).animateTo(1);
                        },
                        child: const Text("Veure tot"),
                      ),
                    ],
                  ),
                ),
                _buildUpcomingEventsSection(),

                const SizedBox(height: 20),

                // 3. VOTACIONS ACTIVES (AQUÍ ESTÀ L'ARREGALAT)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Votacions Actives",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navegar a la pestanya de votacions (index 2)
                          DefaultTabController.of(context).animateTo(2);
                        },
                        child: const Text("Veure tot"),
                      ),
                    ],
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.votings.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final now = DateTime.now();

                    // Convertim i filtrem de manera segura
                    var activeVotings = snapshot.data!.docs
                        .map((doc) {
                          try {
                            return VotingModel.fromJson(doc);
                          } catch (e) {
                            return null; // Ignorem documents corruptes
                          }
                        })
                        .where((v) {
                          // Filtrem: no null i data futura
                          return v != null && v.endDate.toDate().isAfter(now);
                        })
                        .cast<VotingModel>()
                        .toList();

                    // Ordenem: primer les que acaben abans
                    activeVotings.sort(
                      (a, b) => a.endDate.compareTo(b.endDate),
                    );

                    // Limitem a 3
                    final displayList = activeVotings.take(3).toList();

                    if (displayList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEmptyCard(
                          'No hi ha votacions actives.',
                          isHorizontal: true,
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final voting = displayList[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              child: Icon(
                                getIconData(voting.iconName, type: 'voting'),
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              voting.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Tanca: ${DateFormat('dd MMM HH:mm', 'ca').format(voting.endDate.toDate())}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VotingDetailPage(votingId: voting.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARS ---

  Widget _buildHeader() {
    return Container(
      // Aumentamos un poco el padding de abajo para que quepan los iconos
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. FILA DEL PERFIL (Igual que antes)
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hola, $_userName!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Benvingut a l'App",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 25), // Separación
          // 2. FILA DE ICONOS DE ACCESO RÁPIDO (Aquí es donde los querías)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderIconBtn(
                Icons.description,
                "Docs",
                const DocumentsPage(),
              ),
              _buildHeaderIconBtn(
                Icons.music_note,
                "Música",
                const MusicLibraryPage(),
              ),
              _buildHeaderIconBtn(
                Icons.shopping_bag,
                "Pedidos",
                const OrderSheetsListPage(),
              ), // Usa OrderSheetsPage
              _buildHeaderIconBtn(
                Icons.confirmation_number,
                "Tickets",
                const TicketsPage(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pequeña función auxiliar para diseñar los botones de arriba
  Widget _buildHeaderIconBtn(IconData icon, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // Fondo semitransparente
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.announcements
          .orderBy('date', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Si no hay anuncios, mostramos un botón para crear si es admin
          if (_isAdmin) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAnnouncementPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Crear primer anunci"),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!.docs.first;
        final announcement = AnnouncementModel.fromJson(doc);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade300, Colors.orange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Chip(
                    label: Text("AVÍS IMPORTANT"),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () async {
                        await _firestoreService.announcements
                            .doc(doc.id)
                            .delete();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                announcement.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                announcement.content,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingEventsSection() {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        // Ara sí funcionarà perquè hem afegit la funció al service
        stream: _firestoreService.getEventsListStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();

          // CORRECCIÓ PRINCIPAL AQUÍ:
          final events = snapshot.data!.docs
              .map((doc) {
                // Usem fromJson, que és el nom correcte en el teu model
                return EventModel.fromJson(doc);
              })
              .where((e) {
                // Comprovem que la data existeix abans d'usar-la
                return e.date.toDate().isAfter(
                  now.subtract(const Duration(hours: 4)),
                );
              })
              .toList();

          // Ordenem
          events.sort((a, b) => a.date.compareTo(b.date));

          if (events.isEmpty) {
            return Center(
              child: _buildEmptyCard(
                "No hi ha esdeveniments propers",
                isHorizontal: false,
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event);
            },
          );
        },
      ),
    );
  }

  // Cards Components
  Widget _buildEventCard(EventModel event) {
    bool hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(event.imageUrl!),
                  fit: BoxFit.cover,
                  opacity: 0.8,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          // Gradient overlay for text readability if image exists
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: hasImage
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  )
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!hasImage) ...[
                Center(
                  child: Icon(
                    getIconData(event.iconName, type: 'event'),
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
              ],
              Text(
                DateFormat('dd MMM - HH:mm', 'ca').format(event.date.toDate()),
                style: TextStyle(
                  color: hasImage ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasImage ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: hasImage ? Colors.white70 : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasImage ? Colors.white70 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text, {bool isHorizontal = true}) {
    return Container(
      width: isHorizontal ? double.infinity : 200,
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }
}
