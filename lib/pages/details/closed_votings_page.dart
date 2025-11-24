// lib/pages/details/closed_votings_page.dart
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/pages/details/voting_detail_page.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Aquesta pantalla és només per a Administradors.
///
/// Mostra una llista de les votacions que s'han tancat
/// en les últimes 48 hores, per a poder consultar els resultats.
class ClosedVotingsPage extends StatelessWidget {
  const ClosedVotingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Votacions Tancades')),
      // Utilitzem un StreamBuilder per a llegir la nova funció del servei.
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getRecentlyClosedVotingsStream(),
        builder: (context, snapshot) {
          // Casos de càrrega, error o dades buides.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No s\'ha tancat cap votació en les últimes 48 hores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          // Convertim els documents al nostre model.
          final List<VotingModel> votings = snapshot.data!.docs
              .map((doc) => VotingModel.fromJson(doc))
              .toList();

          // Construïm la llista.
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            itemCount: votings.length,
            itemBuilder: (context, index) {
              final voting = votings[index];
              // Formategem la data de *tancament*.
              final formattedDate = DateFormat(
                'd MMMM, yyyy - HH:mm',
                'ca',
              ).format(voting.endDate.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  // Icona dinàmica
                  leading: CircleAvatar(
                    backgroundColor:
                        Colors.grey[700], // Un color diferent per a l'arxiu
                    child: Icon(
                      getIconData(voting.iconName, type: 'voting'),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    voting.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.lineThrough, // Ratllem el text
                    ),
                  ),
                  subtitle: Text('Tancada el: $formattedDate'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // En fer clic, anem a la pàgina de detall que ja tenim.
                    // Aquesta pàgina ja sap com mostrar els resultats
                    // d'una votació caducada (gràcies al bug que vam arreglar!).
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
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
    );
  }
}
