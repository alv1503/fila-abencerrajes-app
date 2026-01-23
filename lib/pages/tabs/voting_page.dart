// lib/pages/tabs/voting_page.dart
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:abenceapp/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/pages/details/voting_detail_page.dart';
import 'package:abenceapp/pages/forms/add_voting_page.dart';
import 'package:abenceapp/utils/icon_helper.dart';
import 'package:abenceapp/pages/details/closed_votings_page.dart';

class VotingPage extends StatefulWidget {
  const VotingPage({super.key});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isAdmin = false;
  bool _isSenior = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final MemberModel member = await _firestoreService.getMemberDetails(
        currentUser.uid,
      );
      if (mounted) {
        setState(() {
          _isAdmin = member.isAdmin;
          _isSenior = member.isSenior;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votacions'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Votacions Tancades',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClosedVotingsPage(),
                ),
              ),
            ),
        ],
      ),

      body: !_isSenior
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Accés Restringit',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Només els membres Senior (majors de 21 anys) tenen dret a vot.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getVotingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                // FILTRO DE FECHAS APLICADO AQUÍ
                final now = DateTime.now();
                
                // 1. Convertimos a lista de modelos
                // 2. Filtramos solo las futuras (isAfter now)
                final List<VotingModel> votings = snapshot.data?.docs
                    .map((doc) => VotingModel.fromJson(doc))
                    .where((v) => v.endDate.toDate().isAfter(now))
                    .toList() ?? [];

                // 3. Ordenamos: las que caducan antes, salen primero
                votings.sort((a, b) => a.endDate.compareTo(b.endDate));

                if (votings.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No hi ha votacions actives en aquest moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  itemCount: votings.length,
                  itemBuilder: (context, index) {
                    final voting = votings[index];
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
                        // --- FOTO O ICONA ---
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          backgroundImage:
                              (voting.imageUrl != null &&
                                  voting.imageUrl!.isNotEmpty)
                              ? NetworkImage(voting.imageUrl!)
                              : null,
                          child:
                              (voting.imageUrl == null ||
                                  voting.imageUrl!.isEmpty)
                              ? Icon(
                                  getIconData(voting.iconName, type: 'voting'),
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                        ),
                        title: Text(
                          voting.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Tanca el: $formattedDate'),
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

      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddVotingPage(),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}