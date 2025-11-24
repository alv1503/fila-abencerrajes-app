// lib/pages/details/voting_detail_page.dart
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/utils/icon_helper.dart';
// --- IMPORT NECESSARI ---
import 'package:abenceapp/pages/details/pdf_viewer_page.dart';

class VotingDetailPage extends StatefulWidget {
  final String votingId;
  const VotingDetailPage({super.key, required this.votingId});

  @override
  State<VotingDetailPage> createState() => _VotingDetailPageState();
}

class _VotingDetailPageState extends State<VotingDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String? _selectedOption;
  List<String> _selectedOptions = [];
  bool _isChangingVote = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final MemberModel member = await _firestoreService.getMemberDetails(
        _currentUserId,
      );
      if (mounted) setState(() => _isAdmin = member.isAdmin);
    } catch (e) {
      /*...*/
    }
  }

  Future<void> _deleteVoting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esborrar Votació'),
        content: const Text('Estàs segur?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esborrar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestoreService.deleteVoting(widget.votingId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        /*...*/
      }
    }
  }

  Future<void> _castVote(VotingModel voting, bool hasVoted) async {
    if (voting.endDate.toDate().isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votació tancada.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    bool isValid = voting.allowMultipleChoices
        ? _selectedOptions.isNotEmpty
        : _selectedOption != null;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona almenys una opció.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    dynamic voteData = voting.allowMultipleChoices
        ? _selectedOptions
        : _selectedOption;
    String displayVote = voting.allowMultipleChoices
        ? _selectedOptions.join(", ")
        : _selectedOption!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasVoted ? 'Canviar Vot' : 'Confirmar Vot'),
        content: Text('Vols votar per: "$displayVote"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(hasVoted ? 'Canviar' : 'Votar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await _firestoreService.castVote(widget.votingId, voteData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vot registrat!'),
            backgroundColor: Colors.green,
          ),
        );
        if (hasVoted) setState(() => _isChangingVote = false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, double> _calculateResults(VotingModel voting) {
    final Map<String, int> voteCounts = {};
    int totalVotes = voting.results.length;
    if (totalVotes == 0) {
      return {for (var option in voting.options) option: 0.0};
    }
    for (var option in voting.options) {
      voteCounts[option] = 0;
    }
    for (var voteData in voting.results.values) {
      if (voteData is List) {
        for (var option in voteData) {
          if (voteCounts.containsKey(option)) {
            voteCounts[option] = voteCounts[option]! + 1;
          }
        }
      } else {
        if (voteCounts.containsKey(voteData)) {
          voteCounts[voteData] = voteCounts[voteData]! + 1;
        }
      }
    }
    final Map<String, double> results = {};
    for (var entry in voteCounts.entries) {
      results[entry.key] = (entry.value / totalVotes) * 100;
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getVotingDocumentStream(widget.votingId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final VotingModel voting = VotingModel.fromJson(snapshot.data!);
          final dynamic userVoteData = voting.results[_currentUserId];
          final bool hasVoted = userVoteData != null;
          final bool isExpired = voting.endDate.toDate().isBefore(
            DateTime.now(),
          );

          if (hasVoted && _isChangingVote) {
            if (voting.allowMultipleChoices) {
              if (_selectedOptions.isEmpty && userVoteData is List) {
                _selectedOptions = List<String>.from(userVoteData);
              }
            } else {
              if (_selectedOption == null && userVoteData is String) {
                _selectedOption = userVoteData;
              }
            }
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    voting.title,
                    style: const TextStyle(
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  background:
                      voting.imageUrl != null && voting.imageUrl!.isNotEmpty
                      ? Image.network(voting.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            getIconData(voting.iconName, type: 'voting'),
                            size: 100,
                            color: Colors.black38,
                          ),
                        ),
                ),
                actions: [
                  if (_isAdmin)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: _deleteVoting,
                    ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Tanca: ${DateFormat('dd MMM HH:mm').format(voting.endDate.toDate())}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          voting.description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontSize: 16),
                        ),

                        // --- BOTÓ VEURE ADJUNT ---
                        if (voting.attachedFileUrl != null &&
                            voting.attachedFileUrl!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 20, bottom: 10),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PdfViewerPage(
                                      pdfUrl: voting.attachedFileUrl!,
                                      title:
                                          voting.attachedFileName ??
                                          'Document Adjunt',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.description),
                              label: Text(
                                "Veure Document: ${voting.attachedFileName ?? 'PDF'}",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),

                        const Divider(height: 40),

                        if (isExpired) ...[
                          Text(
                            'Resultats Finals',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          ..._calculateResults(voting).entries.map(
                            (e) =>
                                _buildResultBar(context, e.key, e.value, false),
                          ),
                        ],

                        if (!isExpired) ...[
                          if (!hasVoted || _isChangingVote) ...[
                            Text(
                              voting.allowMultipleChoices
                                  ? 'Selecciona opcions (Múltiple):'
                                  : 'Selecciona una opció:',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            ...voting.options.map((option) {
                              return Card(
                                child: voting.allowMultipleChoices
                                    ? CheckboxListTile(
                                        title: Text(
                                          option,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        value: _selectedOptions.contains(
                                          option,
                                        ),
                                        onChanged: (val) => setState(() {
                                          if (val == true) {
                                            _selectedOptions.add(option);
                                          } else {
                                            _selectedOptions.remove(option);
                                          }
                                        }),
                                      )
                                    : RadioListTile<String>(
                                        title: Text(
                                          option,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        value: option,
                                        groupValue: _selectedOption,
                                        onChanged: (val) => setState(
                                          () => _selectedOption = val,
                                        ),
                                      ),
                              );
                            }),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _castVote(voting, hasVoted),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              child: Text(
                                _isChangingVote
                                    ? 'Confirmar Canvi'
                                    : 'Emetre Vot',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            if (_isChangingVote)
                              TextButton(
                                onPressed: () => setState(() {
                                  _isChangingVote = false;
                                  _selectedOption = null;
                                  _selectedOptions = [];
                                }),
                                child: const Text('Cancel·lar canvi'),
                              ),
                          ],

                          if (hasVoted && !_isChangingVote) ...[
                            Text(
                              'Resultats Actuals',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            ..._calculateResults(voting).entries.map((e) {
                              bool isUserVote = (userVoteData is List)
                                  ? userVoteData.contains(e.key)
                                  : userVoteData == e.key;
                              return _buildResultBar(
                                context,
                                e.key,
                                e.value,
                                isUserVote,
                              );
                            }),
                            const SizedBox(height: 20),
                            Text(
                              'Has votat: ${userVoteData is List ? userVoteData.join(", ") : userVoteData}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () =>
                                  setState(() => _isChangingVote = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Canviar Vot'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultBar(
    BuildContext context,
    String option,
    double percentage,
    bool isUserVote,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isUserVote ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  color: isUserVote
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                  fontWeight: isUserVote ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
            color: isUserVote
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
