// lib/auth/auth_gate.dart
import 'package:abenceapp/app.dart';
import 'package:abenceapp/auth/login_page.dart';
import 'package:abenceapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// El [AuthGate] és el primer widget que es carrega en l'app.
///
/// Escolta els canvis d'autenticació de Firebase per a decidir automàticament
/// si s'ha de mostrar la [HomePage] (si l'usuari està loguejat)
/// o la [LoginPage] (si no ho està).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Escolta el 'stream' de l'estat d'autenticació des del nostre AuthService.
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // 1. L'usuari SÍ està loguejat (la 'snapshot' té dades)
          if (snapshot.hasData) {
            return const HomePage();
          }
          // 2. L'usuari NO està loguejat
          else {
            // Mostrem la pàgina de login.
            return LoginPage(
              onTap: () {
                // Aquesta funció 'onTap' es va crear originalment per a anar
                // a una pàgina de registre, però ara mateix no fa res.
                // La [LoginPage] encara espera rebre-la.
              },
            );
          }
        },
      ),
    );
  }
}
