// lib/app.dart
import 'package:abenceapp/pages/tabs/events_page.dart';
import 'package:abenceapp/pages/tabs/home_feed_page.dart';
import 'package:abenceapp/pages/tabs/members_page.dart';
import 'package:abenceapp/pages/tabs/profile_page.dart';
import 'package:abenceapp/pages/tabs/voting_page.dart';
import 'package:flutter/material.dart';

import 'package:abenceapp/theme/app_theme.dart';
import 'package:abenceapp/auth/auth_gate.dart';

/// El widget principal de l'aplicació.
///
/// Defineix el [MaterialApp], el tema (fosc) i la [AuthGate] com a
/// punt d'entrada inicial.
class AbencerrajesApp extends StatelessWidget {
  const AbencerrajesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Utilitza el tema fosc definit
      home:
          const AuthGate(), // El punt d'entrada que decideix si mostrar Login o Home
    );
  }
}

/// El widget que conté la navegació principal per pestanyes (tabs).
///
/// Aquest [StatefulWidget] gestiona la barra de navegació inferior
/// ([BottomNavigationBar]) i manté l'estat de la pestanya seleccionada.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // L'índex de la pestanya seleccionada actualment.
  // Comença en 2, que correspon a la pestanya "Inici" (la del mig).
  int _selectedIndex = 2;

  // Llista estàtica de les 5 pantalles (pestanyes) que es mostraran.
  // L'ordre ací ha de coincidir amb l'ordre de la [BottomNavigationBar].
  static const List<Widget> _pages = [
    MembersPage(),
    EventsPage(),
    HomeFeedPage(),
    VotingPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El cos de l'Scaffold mostra la pàgina seleccionada de la llista _pages.
      body: Center(child: _pages.elementAt(_selectedIndex)),

      // La barra de navegació inferior.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Membres'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Esdeveniments',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inici'),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Votacions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex, // Marca la icona de la pestanya activa.
        // Funció que s'executa quan es toca una icona.
        // Actualitza l'estat amb el nou índex.
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
