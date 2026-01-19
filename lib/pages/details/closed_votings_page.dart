// lib/pages/details/closed_votings_page.dart
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:abenceapp/pages/details/voting_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClosedVotingsPage extends StatefulWidget {
  const ClosedVotingsPage({super.key});

  @override
  State<ClosedVotingsPage> createState() => _ClosedVotingsPageState();
}

class _ClosedVotingsPageState extends State<ClosedVotingsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Històric de Votacions')),
      body: StreamBuilder<QuerySnapshot>(
        // Demanem TOTES les votacions
        stream: _firestoreService.votings
            .orderBy('endDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hi ha votacions registrades.'));
          }

          // Filtrem manualment les que ja han passat (Closed)
          // Això és més segur que fer-ho en la query per evitar problemes d'índexs
          final now = DateTime.now();
          final allDocs = snapshot.data!.docs;

          final closedVotings = allDocs
              .where((doc) {
                try {
                  // Usem el model segur que hem creat abans
                  final voting = VotingModel.fromJson(doc);
                  return voting.endDate.toDate().isBefore(now);
                } catch (e) {
                  // Si un document està tan malament que falla, l'ignorem
                  return false;
                }
              })
              .map((doc) => VotingModel.fromJson(doc))
              .toList();

          if (closedVotings.isEmpty) {
            return const Center(child: Text('No hi ha votacions passades.'));
          }

          return ListView.builder(
            itemCount: closedVotings.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final voting = closedVotings[index];
              final dateStr = DateFormat(
                'dd/MM/yyyy',
              ).format(voting.endDate.toDate());

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      getIconData(voting.iconName, type: 'voting'),
                      color: Colors.grey[700],
                    ),
                  ),
                  title: Text(
                    voting.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Finalitzada el: $dateStr'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
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
