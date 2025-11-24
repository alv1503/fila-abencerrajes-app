// lib/auth/login_page.dart
import 'package:abenceapp/services/auth_service.dart';
import 'package:flutter/material.dart';

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
        _emailController.text,
        _passwordController.text,
      );
      // Si tenim èxit, no cal fer res més.
      // L'[AuthGate] (que està escoltant) detectarà el canvi d'estat
      // i navegarà automàticament a la [HomePage].
    } catch (e) {
      // Captura qualsevol error que ocórrega durant el login.
      // Revisa si el widget encara està "muntat" (visible)
      // abans de mostrar un SnackBar.
      if (mounted) {
        // Personalitzem el missatge d'error segons el codi de Firebase.
        String errorMessage = 'Error en iniciar sessió';
        if (e.toString().contains('INVALID_LOGIN_CREDENTIALS')) {
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
      }
    } finally {
      // El bloc 'finally' s'executa sempre, tant si hi ha èxit com si hi ha error.
      // Ens assegurem de desactivar l'indicador de càrrega.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

              // Camp de Contrasenya (DNI).
              TextFormField(
                controller: _passwordController,
                obscureText: true, // Oculta el text de la contrasenya.
                decoration: const InputDecoration(
                  labelText: 'Contrasenya (DNI 8 números)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number, // Mostra el teclat numèric.
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

              // Text per a contactar amb un admin (abans 'Registrar-se').
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No tens compte?'),
                  const SizedBox(width: 4),
                  GestureDetector(
                    // Crida a la funció 'onTap' que hem rebut del [AuthGate].
                    onTap: widget.onTap,
                    child: Text(
                      'Contacta amb un admin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
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
