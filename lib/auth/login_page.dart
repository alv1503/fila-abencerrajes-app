// lib/auth/login_page.dart
import 'package:abenceapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:abenceapp/auth/activate_account_page.dart';
import 'package:abenceapp/auth/auth_gate.dart'; // <--- IMPORTANTE: Necesario para la redirección

/// La pàgina d'inici de sessió.
///
/// Proporciona camps per a email i contrasenya (DNI).
/// Gestiona l'estat de càrrega (`_isLoading`) durant el procés de login.
class LoginPage extends StatefulWidget {
  // Funció per a canviar a la pàgina de registre (ara només un text).
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladors per als camps de text d'email i contrasenya.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instància del nostre servei d'autenticació.
  final AuthService _authService = AuthService();

  // Controla l'estat de càrrega per a mostrar/ocultar l'indicador de progrés.
  bool _isLoading = false;

  @override
  void dispose() {
    // Alliberem els controladors quan el widget es destrueix per a evitar
    // problemes de memòria.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Funció principal per a gestionar l'inici de sessió.
  void _login(BuildContext context) async {
    // Bloqueja el botó si ja s'està processant una petició.
    if (_isLoading) return;

    // Activa l'indicador de càrrega i redibuixa el widget.
    setState(() {
      _isLoading = true;
    });

    try {
      // Intenta iniciar sessió amb el servei d'autenticació.
      await _authService.signInWithEmailPassword(
        _emailController.text.trim(), // Afegit trim() per seguretat
        _passwordController.text.trim(),
      );

      // --- CANVI CLAU: Redirecció forçada ---
      if (mounted) {
        // Forzamos la navegación a la puerta principal (AuthGate)
        // Usamos pushAndRemoveUntil para borrar el historial y que no puedan volver atrás
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      // Captura qualsevol error que ocórrega durant el login.
      // Revisa si el widget encara està "muntat" (visible)
      // abans de mostrar un SnackBar.
      if (mounted) {
        // Personalitzem el missatge d'error segons el codi de Firebase.
        String errorMessage = 'Error en iniciar sessió';
        if (e.toString().contains('INVALID_LOGIN_CREDENTIALS') ||
            e.toString().contains('invalid-credential')) {
          errorMessage = 'Email o contrasenya incorrectes.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'El format de l\'email no és vàlid.';
        }

        // Mostra una barra d'error a la part inferior.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );

        // Si falla, llevem la càrrega perquè puguen tornar a intentar-ho
        setState(() {
          _isLoading = false;
        });
      }
    }
    // Nota: He llevat el 'finally' per a evitar conflictes amb la navegació
    // Si tot va bé, canviem de pantalla i no cal fer setState(false).
    // Si va malament, el catch ja fa el setState(false).
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        // Fem que la pàgina siga 'scrollable' per a evitar que el teclat
        // tape els camps de text en pantalles menudes.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona/Logo de l'app.
              Icon(
                Icons.shield_moon,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Benvingut a Abencerrajes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),

              // Camp d'Email.
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 16),

              // Camp de Contrasenya.
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                // Habilita lletres, números i símbols
                keyboardType: TextInputType.visiblePassword,

                decoration: const InputDecoration(
                  labelText: 'Contrasenya',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Introdueix la contrasenya' : null,
              ),
              const SizedBox(height: 24),

              // Botó d'inici de sessió.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Si '_isLoading' és true, 'onPressed' és nul (botó desactivat).
                  onPressed: _isLoading ? null : () => _login(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      // Mostra l'indicador de càrrega si s'està processant.
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Iniciar Sessió',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Enllaç per activar compte
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('És la teua primera vegada?'),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivateAccountPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Activa el teu compte ací',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
