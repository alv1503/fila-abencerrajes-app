// lib/pages/extras/music_library_page.dart
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicLibraryPage extends StatefulWidget {
  const MusicLibraryPage({super.key});

  @override
  State<MusicLibraryPage> createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('No es pot obrir $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error obrint l\'enllaç')));
      }
    }
  }

  void _showAddMusicDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Afegir Marxa/Himne"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Comparteix la teua música preferida amb la Filà.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "Títol (Ex: Chimo)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: "Enllaç (YouTube/Spotify)",
                border: OutlineInputBorder(),
                hintText: "https://...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel·lar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                _firestoreService.addMusicLink(
                  titleController.text.trim(),
                  urlController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Afegit correctament!')),
                );
              }
            },
            child: const Text("Afegir"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca Musical')),
      // BOTÓ D'AFEGIR DISPONIBLE PER A TOTS
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMusicDialog,
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getMusicLinksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No hi ha música encara.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    "Sigues el primer en afegir-ne!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final songs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: songs.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final song = songs[index].data() as Map<String, dynamic>;
              final String id = songs[index].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: const Icon(Icons.play_arrow, color: Colors.red),
                ),
                title: Text(
                  song['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  song['url'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.blue),
                ),
                // NOMÉS ELS ADMINS PODEN ESBORRAR (Per seguretat)
                trailing: _isAdmin
                    ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => _firestoreService.deleteMusicLink(id),
                      )
                    : const Icon(
                        Icons.open_in_new,
                        color: Colors.grey,
                        size: 20,
                      ),
                onTap: () => _launchURL(song['url']),
              );
            },
          );
        },
      ),
    );
  }
}
