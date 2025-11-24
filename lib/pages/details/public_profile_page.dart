// lib/pages/details/public_profile_page.dart
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:flutter/material.dart';

/// La pàgina de perfil públic d'un membre.
///
/// Rep l'ID d'un membre ([memberId]) i utilitza un [FutureBuilder]
/// per a obtindre les seues dades una sola vegada.
///
/// Aquesta pàgina **oculta** informació sensible (DNI, quota, etc.)
/// i només mostra dades públiques o de contacte.
class PublicProfilePage extends StatelessWidget {
  // L'ID del membre que volem mostrar.
  final String memberId;
  const PublicProfilePage({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    // Instanciem el servei ací dins, ja que és un StatelessWidget.
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del Membre')),
      // Utilitzem un FutureBuilder perquè només necessitem carregar
      // les dades una vegada (no calen actualitzacions en temps real).
      body: FutureBuilder<MemberModel>(
        // El 'future' és la crida al servei per a obtindre les dades.
        future: firestoreService.getMemberDetails(memberId),
        builder: (context, snapshot) {
          // Casos de càrrega, error o dades buides.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Membre no trobat.'));
          }

          // Un cop tenim les dades, les convertim al nostre model.
          final MemberModel member = snapshot.data!;
          final String? fotoUrl = member.fotoUrl;

          // Retornem la columna amb la informació.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // --- AVATAR (Lògica idèntica a la del perfil privat) ---
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                        ? NetworkImage(fotoUrl)
                        : null,
                    child: (fotoUrl == null || fotoUrl.isEmpty)
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
                ),
                const SizedBox(height: 16),

                // --- Noms i Mote ---
                Center(
                  child: Text(
                    member.mote,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${member.nom} ${member.cognoms}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                const Divider(height: 30),

                // --- Targeta "Sobre mi" (només si existeix) ---
                if (member.descripcio != null && member.descripcio!.isNotEmpty)
                  _buildInfoCard(
                    context,
                    title: "Sobre mi",
                    children: [
                      Text(
                        member.descripcio!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                if (member.descripcio != null && member.descripcio!.isNotEmpty)
                  const SizedBox(height: 20),

                // --- Targeta "Dades de Contacte" ---
                _buildInfoCard(
                  context,
                  title: "Dades de Contacte",
                  children: [
                    _ProfileInfoTile(
                      context: context,
                      icon: Icons.email_outlined,
                      title: member.email,
                      subtitle: "Correu Electrònic",
                    ),
                    _ProfileInfoTile(
                      context: context,
                      icon: Icons.phone_outlined,
                      title: member.telefon,
                      subtitle: "Telèfon",
                    ),
                  ],
                ),

                // --- IMPORTANT ---
                // Ací no mostrem les targetes de "Dades Personals" (DNI)
                // ni "Dades de la Filà" (quota), ja que és un perfil públic.
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS D'AJUDA (Helpers) ---
  // Aquests són els mateixos widgets d'ajuda que a 'profile_page.dart'
  // per a mantindre la coherència visual.

  /// Construeix un widget [Card] estandarditzat per a la informació.
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

  /// Construeix un widget [ListTile] estandarditzat per a una línia d'informació.
  /// Necessita el [context] per a accedir als colors del tema.
  /// (Aquesta era la funció que tenia el "fallo" del context)
  Widget _ProfileInfoTile({
    required BuildContext context, // <-- ¡CORRECCIÓ! Rep el context
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
