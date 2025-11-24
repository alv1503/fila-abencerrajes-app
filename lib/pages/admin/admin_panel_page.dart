// lib/pages/admin/admin_panel_page.dart
import 'package:abenceapp/pages/admin/create_user_page.dart';
import 'package:abenceapp/pages/admin/admin_feedback_page.dart';
import 'package:abenceapp/pages/admin/family_manager_page.dart'; // Assegura't que el nom coincideix amb el teu arxiu
import 'package:abenceapp/services/excel_service.dart';
import 'package:abenceapp/services/firestore_service.dart'; // AQUEST IMPORT ERA EL QUE FALTAVA
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panell d\'Administració')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Gestió d\'Usuaris',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          // 1. CREAR USUARI
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Donar d\'alta nou usuari'),
            subtitle: const Text('Crear compte per a un nou soci'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateUserPage()),
              );
            },
          ),
          const Divider(),

          // 2. VINCULACIÓ FAMILIAR
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Gestió Familiar'),
            subtitle: const Text('Vincular pares i fills'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FamilyManagerPage(),
                ),
              );
            },
          ),
          const Divider(),

          // 3. EXPORTAR CENS
          ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text('Exportar Cens a Excel'),
            subtitle: const Text('Descarregar llistat complet de socis'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generant Excel...')),
              );
              try {
                final snapshot = await FirebaseFirestore.instance
                    .collection('membres')
                    .get();
                await ExcelService().exportMemberCensus(snapshot.docs);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Comunicació',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          // 4. BÚSTIA DE SUGGERIMENTS
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Bústia de Suggeriments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminFeedbackPage(),
                ),
              );
            },
          ),
          const Divider(),

          // --- NOVA SECCIÓ: SISTEMA ---
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Manteniment del Sistema',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          // 5. GARBAGE COLLECTOR (NETEJA)
          ListTile(
            leading: const Icon(Icons.cleaning_services, color: Colors.orange),
            title: const Text('Alliberar Espai (Neteja)'),
            subtitle: const Text('Esborrar adjunts d\'actes antics (+30 dies)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Diàleg de confirmació
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Manteniment"),
                  content: const Text(
                    "Això esborrarà els PDFs adjunts d'esdeveniments i votacions finalitzats fa més de 30 dies.\n\nEls arxius de la secció 'Documentació' NO es tocaran.\n\nVols continuar?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel·lar"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Netejar"),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Analitzant i netejant... (Pot tardar un poc)',
                    ),
                  ),
                );

                try {
                  // Cridem a la funció del servei
                  int count = await FirestoreService().cleanOldAttachments();

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Neteja Completada"),
                        content: Text(
                          "S'han eliminat $count arxius antics i s'ha alliberat espai al núvol.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Perfecte"),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
