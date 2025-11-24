// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Un servei per a gestionar totes les operacions d'autenticació
/// amb Firebase Authentication.
class AuthService {
  // Instància principal de Firebase Auth.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. Iniciar Sessió ---
  /// Intenta iniciar sessió amb un email i contrasenya.
  ///
  /// Retorna les credencials de l'usuari si té èxit.
  /// Llança una excepció amb el codi d'error si falla.
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) {
    try {
      // Mètode de Firebase per a iniciar sessió.
      return _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Si falla, llança una excepció simple amb el codi d'error
      // (Ex: 'INVALID_LOGIN_CREDENTIALS') perquè la [LoginPage]
      // la capture i mostre un missatge amigable.
      throw Exception(e.code);
    }
  }

  // --- 2. Tancar Sessió ---
  /// Tanca la sessió de l'usuari actual.
  Future<void> signOut() {
    return _auth.signOut();
  }

  // --- 3. Obtindre l'usuari actual ---
  /// Retorna l'objecte [User] de Firebase si està loguejat,
  /// o 'null' si no ho està.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // --- 4. Stream d'estat d'autenticació ---
  /// Aquest és el 'stream' clau que utilitza l'[AuthGate].
  ///
  /// Emet un [User] quan l'usuari inicia sessió.
  /// Emet 'null' quan l'usuari tanca la sessió.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
