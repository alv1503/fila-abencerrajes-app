import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/models/voting_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/utils/icon_helper.dart';
// Assegura't que tens aquest import o comenta'l si no uses PDF encara
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
  bool _isLoading = false;

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
      debugPrint('Error admin: $e');
    }
  }

  // --- ENVIAR VOT ---
  Future<void> _submitVote(VotingModel voting) async {
    // Validacions
    if (voting.allowMultipleChoices) {
      if (_selectedOptions.isEmpty) return;
    } else {
      if (_selectedOption == null) return;
    }

    setState(() => _isLoading = true);

    try {
      dynamic voteData = voting.allowMultipleChoices
          ? _selectedOptions
          : _selectedOption;

      // CRIDA A LA FUNCIÓ NOVA QUE HAS AFEGIT AL SERVICE
      await _firestoreService.submitVote(
        widget.votingId,
        _currentUserId,
        voteData,
      );

      if (mounted) {
        setState(() => _isChangingVote = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vot registrat correctament!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al votar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ESBORRAR VOT ---
  Future<void> _removeVote() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.removeVote(widget.votingId, _currentUserId);
      if (mounted) {
        setState(() {
          _selectedOption = null;
          _selectedOptions = [];
          _isChangingVote = true;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CÀLCUL DE RESULTATS ---
  Map<String, double> _calculatePercentages(VotingModel voting) {
    Map<String, double> percentages = {};
    for (var option in voting.options) {
      percentages[option] = 0.0;
    }

    int totalVotesCount = 0;
    voting.results.forEach((userId, voteContent) {
      if (voteContent is String) {
        if (percentages.containsKey(voteContent)) {
          percentages[voteContent] = percentages[voteContent]! + 1;
          totalVotesCount++;
        }
      } else if (voteContent is List) {
        for (var option in voteContent) {
          if (percentages.containsKey(option)) {
            percentages[option] = percentages[option]! + 1;
            totalVotesCount++;
          }
        }
      }
    });

    if (totalVotesCount > 0) {
      percentages.forEach((key, value) {
        percentages[key] = (value / totalVotesCount) * 100;
      });
    }
    return percentages;
  }

  void _toggleOption(String option, bool isMultiple) {
    setState(() {
      if (isMultiple) {
        if (_selectedOptions.contains(option)) {
          _selectedOptions.remove(option);
        } else {
          _selectedOptions.add(option);
        }
      } else {
        _selectedOption = option;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.votings.doc(widget.votingId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        // Si el document no existeix (esborrat)
        if (!snapshot.data!.exists)
          return const Scaffold(
            body: Center(child: Text('Votació no trobada')),
          );

        final voting = VotingModel.fromJson(snapshot.data!);
        final bool isExpired = voting.endDate.toDate().isBefore(DateTime.now());
        final bool hasVoted = voting.results.containsKey(_currentUserId);

        // Recuperar el meu vot per pintar-lo
        dynamic myVote = voting.results[_currentUserId];
        bool userVotedThis(String option) {
          if (!hasVoted) return false;
          if (myVote is String) return myVote == option;
          if (myVote is List) return myVote.contains(option);
          return false;
        }

        final percentages = _calculatePercentages(voting);
        final bool showResults = (hasVoted && !_isChangingVote) || isExpired;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Votació'),
            actions: [
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Esborrar votació?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Si"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _firestoreService.votings
                          .doc(widget.votingId)
                          .delete();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      getIconData(voting.iconName, type: 'voting'),
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voting.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Tanca: ${DateFormat('dd/MM/yyyy HH:mm').format(voting.endDate.toDate())}',
                            style: TextStyle(
                              color: isExpired ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(voting.description),

                // PDF Adjunt
                if (voting.attachedFileUrl != null &&
                    voting.attachedFileUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                        ),
                        title: Text(
                          voting.attachedFileName ?? 'Document Adjunt',
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerPage(
                              pdfUrl: voting.attachedFileUrl!,
                              title: voting.title,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 32),

                // ZONA DE RESULTATS O VOTAR
                if (showResults) ...[
                  Text(
                    'Resultats (${voting.results.length} vots)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...voting.options.map((option) {
                    final percent = percentages[option] ?? 0.0;
                    final isMyVote = userVotedThis(option);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                fontWeight: isMyVote
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isMyVote ? Colors.green : Colors.black,
                              ),
                            ),
                            Text('${percent.toStringAsFixed(1)}%'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                          color: isMyVote
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                          backgroundColor: Colors.grey[200],
                        ),
                        if (isMyVote)
                          const Text(
                            "(El teu vot)",
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  if (!isExpired && hasVoted)
                    Center(
                      child: TextButton.icon(
                        onPressed: _removeVote,
                        icon: const Icon(Icons.edit),
                        label: const Text("Canviar el meu vot"),
                      ),
                    ),
                ] else ...[
                  if (isExpired)
                    const Center(
                      child: Text(
                        "Finalitzada",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    )
                  else ...[
                    Text(
                      voting.allowMultipleChoices
                          ? 'Tria (Múltiple)'
                          : 'Tria una opció',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...voting.options.map((option) {
                      final isSelected = voting.allowMultipleChoices
                          ? _selectedOptions.contains(option)
                          : _selectedOption == option;
                      return Card(
                        elevation: 0,
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => _toggleOption(
                            option,
                            voting.allowMultipleChoices,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? (voting.allowMultipleChoices
                                            ? Icons.check_box
                                            : Icons.radio_button_checked)
                                      : (voting.allowMultipleChoices
                                            ? Icons.check_box_outline_blank
                                            : Icons.radio_button_off),
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: () => _submitVote(voting),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ENVIAR VOT'),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
