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
import 'package:abenceapp/pages/forms/feedback_page.dart';
import 'package:abenceapp/auth/login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _needsRefresh = false;

  Future<void> _openDownloadPage() async {
    // CAMBIAR ESTO LUEGO POR LA SOLUCIÓN QUE ELIJAS
    final Uri url = Uri.parse(
      'https://abencerrajes-app.web.app/abencerrajes.apk',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('No es pot obrir $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _needsRefresh = !_needsRefresh);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToEdit(MemberModel member) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(currentMember: member),
      ),
    );
    _refreshData();
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('El meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            tooltip: 'Enviar suggeriment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.members.doc(_currentUserId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData || !snapshot.data!.exists)
              return const Center(child: Text('Usuari no trobat.'));

            MemberModel member = MemberModel.fromJson(snapshot.data!);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context, member),
                  const SizedBox(height: 24),

                  _buildInfoCard(
                    context,
                    title: 'Informació Personal',
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.cake,
                        title: 'Data de Naixement',
                        subtitle: member.dataNaixement != null
                            ? DateFormat(
                                'dd/MM/yyyy',
                              ).format(member.dataNaixement!.toDate())
                            : 'No especificada',
                      ),
                      const Divider(),
                      _ProfileInfoTile(
                        icon: Icons.location_on,
                        title: 'Adreça',
                        subtitle: member.adreca.isNotEmpty
                            ? member.adreca
                            : 'No especificada',
                      ),
                      const Divider(),
                      _ProfileInfoTile(
                        icon: Icons.info_outline,
                        title: 'Descripció',
                        subtitle: member.descripcio?.isNotEmpty == true
                            ? member.descripcio!
                            : 'Sense descripció',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildInfoCard(
                    context,
                    title: 'Dades de Contacte',
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: member.email,
                      ),
                      const Divider(),
                      _ProfileInfoTile(
                        icon: Icons.phone,
                        title: 'Telèfon',
                        subtitle: member.telefon.isNotEmpty
                            ? member.telefon
                            : 'No especificat',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildInfoCard(
                    context,
                    title: 'Informació Festera',
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.badge,
                        title: 'DNI',
                        subtitle: member.dni.isNotEmpty
                            ? member.dni
                            : 'No registrat',
                      ),
                      const Divider(),
                      _ProfileInfoTile(
                        icon: Icons.monetization_on,
                        title: 'Quota',
                        subtitle: member.tipusQuota.toUpperCase(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildInfoCard(
                    context,
                    title: 'Aplicació',
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.system_update,
                        title: 'Buscar Actualitzacions',
                        subtitle: 'Obrir pàgina de descàrregues',
                        onTap: _openDownloadPage, // Aquí sí usamos onTap
                      ),
                      const Divider(),
                      _ProfileInfoTile(
                        icon: Icons.info_outline,
                        title: 'Versió Instal·lada',
                        subtitle: '1.0.2',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  if (member.isAdmin) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Panell d\'Administrador'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPanelPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Tancar Sessió',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tancar Sessió'),
                            content: const Text('Estàs segur?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel·lar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sortir'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) _logout();
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

  // --- WIDGETS AUXILIARES (Restaurados) ---

  Widget _buildHeader(BuildContext context, MemberModel member) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  (member.fotoUrl != null && member.fotoUrl!.isNotEmpty)
                  ? NetworkImage(member.fotoUrl!)
                  : null,
              child: (member.fotoUrl == null || member.fotoUrl!.isEmpty)
                  ? Text(
                      member.nom.isNotEmpty ? member.nom[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  onPressed: () => _navigateToEdit(member),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${member.nom} ${member.cognoms}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (member.mote.isNotEmpty)
          Text(
            '"${member.mote}"',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

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
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  // AQUÍ ESTÁ EL ARREGLO: onTap es opcional (?)
  Widget _ProfileInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap, // <--- El "?" permite que sea null
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
      trailing: onTap != null
          ? const Icon(Icons.open_in_new, size: 18, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
