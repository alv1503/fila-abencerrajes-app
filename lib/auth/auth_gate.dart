// lib/auth/auth_gate.dart
import 'package:abenceapp/app.dart'; // Aquí está tu HomePage
import 'package:abenceapp/auth/login_page.dart';
import 'package:abenceapp/auth/setup_profile_page.dart'; // Importamos la nueva pantalla
import 'package:abenceapp/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para leer la DB
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // 1. Escuchamos si hay usuario logueado en Firebase Auth
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // Si está cargando la autenticación...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // CASO A: HAY USUARIO LOGUEADO
          if (snapshot.hasData) {
            final User user = snapshot.data!;

            // 2. Ahora escuchamos su documento en Firestore para ver si completó el perfil
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                    'membres',
                  ) // La colección donde guardas los usuarios
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                // Mientras carga la info de la base de datos...
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Si el documento no existe (raro, pero por seguridad) le mandamos al Setup
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SetupProfilePage();
                }

                // Leemos el campo clave
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final bool isSetupComplete =
                    userData['isSetupComplete'] ?? false;

                // DECISIÓN FINAL:
                if (isSetupComplete) {
                  return const HomePage(); // Todo correcto -> A la App
                } else {
                  return const SetupProfilePage(); // Falta info -> Al Formulario
                }
              },
            );
          }
          // CASO B: NO HAY USUARIO -> LOGIN
          else {
            return LoginPage(
              onTap: () {
                // Esta función se usaba para el toggle de registro antiguo.
                // Ahora el registro se hace desde el botón "Activar cuenta" dentro del Login.
              },
            );
          }
        },
      ),
    );
  }
}
