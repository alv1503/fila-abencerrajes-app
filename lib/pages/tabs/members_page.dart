// lib/pages/tabs/members_page.dart
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:abenceapp/pages/details/public_profile_page.dart';

/// La pestanya de Membres.
///
/// Mostra una quadrícula (GridView) de tots els membres de la filà.
/// Permet navegar al perfil públic de cada membre.
class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      // El cos és un StreamBuilder que escolta la col·lecció 'membres'.
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getMembersStream(),
        builder: (context, snapshot) {
          // Casos de càrrega, error o dades buides.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hi ha membres a la llista.'));
          }

          final List<DocumentSnapshot> members = snapshot.data!.docs;

          // Construeix la quadrícula (GridView)
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columnes
              crossAxisSpacing: 12.0, // Espaiat horitzontal
              mainAxisSpacing: 12.0, // Espaiat vertical
              childAspectRatio: 0.8, // Proporció (més alt que ample)
            ),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot doc = members[index];
              final Map<String, dynamic> data =
                  doc.data() as Map<String, dynamic>;

              // Extreu les dades necessàries
              final String mote = data['mote'] ?? 'Sense mote';
              final String memberId = doc.id;
              final String? fotoUrl = data['fotoUrl'];

              // Cada element és una targeta (Card) clicable.
              return GestureDetector(
                onTap: () {
                  // Navega al perfil públic en fer clic.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PublicProfilePage(memberId: memberId),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Avatar del membre.
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                            ? NetworkImage(
                                fotoUrl,
                              ) // Mostra la foto si existeix
                            : null,
                        child: (fotoUrl == null || fotoUrl.isEmpty)
                            // Mostra la inicial del mote si no hi ha foto
                            ? Text(
                                mote.isNotEmpty ? mote[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Mote del membre
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          mote,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
