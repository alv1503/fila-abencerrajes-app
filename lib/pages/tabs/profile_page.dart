// lib/pages/tabs/profile_page.dart
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/auth_service.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abenceapp/pages/forms/edit_profile_page.dart';
import 'package:abenceapp/pages/admin/admin_panel_page.dart';
import 'package:abenceapp/pages/forms/feedback_page.dart'; // Import del Feedback
import 'package:abenceapp/auth/login_page.dart'; // Import del Login

/// La pestanya de Perfil de l'usuari actual (loguejat).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Serveis necessaris
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Obtenim l'ID de l'usuari actual directament d'Auth.
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Variable d'estat per a actualitzar la imatge de perfil a l'instant
  String? _newProfileImageUrl;

  /// Obre el selector d'imatges i puja la imatge
  Future<void> _pickAndUploadImage() async {
    try {
      final String? imageUrl = await _firestoreService.uploadProfileImage();

      if (imageUrl != null) {
        setState(() {
          _newProfileImageUrl = imageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imatge de perfil actualitzada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en pujar la imatge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea evita que el contingut es solape amb la barra d'estat
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.members.doc(_currentUserId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('No s\'han trobat les dades del perfil.'),
              );
            }

            final MemberModel member = MemberModel.fromJson(snapshot.data!);
            final String? currentPhotoUrl =
                _newProfileImageUrl ?? member.fotoUrl;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // --- AVATAR ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            backgroundImage:
                                currentPhotoUrl != null &&
                                    currentPhotoUrl.isNotEmpty
                                ? NetworkImage(currentPhotoUrl)
                                : null,
                            child:
                                (currentPhotoUrl == null ||
                                    currentPhotoUrl.isEmpty)
                                ? Text(
                                    member.mote.isNotEmpty
                                        ? member.mote[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 60,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              radius: 20,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Noms i Mote ---
                  Center(
                    child: Text(
                      member.mote,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${member.nom} ${member.cognoms}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- Botó d'Editar Perfil ---
                  TextButton.icon(
                    icon: Icon(
                      Icons.edit,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    label: Text(
                      'Editar Perfil',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfilePage(currentMember: member),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 30),

                  // --- BOTÓ: PANELL D'ADMINISTRACIÓ ---
                  if (member.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Panell d\'Administració'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[900],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminPanelPage(),
                            ),
                          );
                        },
                      ),
                    ),

                  // --- Targeta "Sobre mi" ---
                  if (member.descripcio != null &&
                      member.descripcio!.isNotEmpty) ...[
                    _buildInfoCard(
                      context,
                      title: "Sobre mi",
                      children: [
                        Text(
                          member.descripcio!,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- Targeta "Dades de Contacte" ---
                  _buildInfoCard(
                    context,
                    title: "Dades de Contacte",
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.email_outlined,
                        title: member.email,
                        subtitle: "Correu Electrònic",
                      ),
                      _ProfileInfoTile(
                        icon: Icons.phone_outlined,
                        title: member.telefon,
                        subtitle: "Telèfon",
                      ),
                      _ProfileInfoTile(
                        icon: Icons.home_outlined,
                        title: member.adreca,
                        subtitle: "Adreça",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Targeta "Dades Personals" ---
                  _buildInfoCard(
                    context,
                    title: "Dades Personals",
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.badge_outlined,
                        title: member.dni,
                        subtitle: "DNI",
                      ),
                      _ProfileInfoTile(
                        icon: Icons.cake_outlined,
                        title: DateFormat(
                          'd MMMM, yyyy',
                          'ca',
                        ).format(member.dataNaixement.toDate()),
                        subtitle: "Data de Naixement",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Targeta "Dades de la Filà" ---
                  _buildInfoCard(
                    context,
                    title: "Dades de la Filà",
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.shield_outlined,
                        title: member.tipusQuota.isNotEmpty
                            ? member.tipusQuota[0].toUpperCase() +
                                  member.tipusQuota.substring(1)
                            : 'No definida',
                        subtitle: "Tipus de Quota",
                      ),
                      _ProfileInfoTile(
                        icon: Icons.work_off_outlined,
                        title: member.enExcedencia ? 'Sí' : 'No',
                        subtitle: "Excedència disponible",
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- ZONA D'ACCIONS DE SISTEMA ---

                  // 1. BOTÓ FEEDBACK / ERROR
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bug_report),
                      label: const Text("Informar d'un error / Suggeriment"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FeedbackPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. BOTÓ TANCAR SESSIÓ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Tancar Sessió'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          await _authService.signOut();
                          if (mounted) {
                            // Fix del problema del onTap: passem una funció buida
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => LoginPage(onTap: () {}),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS D'AJUDA (Helpers) ---

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _ProfileInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
