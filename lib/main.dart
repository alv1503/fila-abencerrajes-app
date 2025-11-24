// lib/main.dart
import 'package:abenceapp/app.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
// (Hemos quitado los imports de notificaciones)

Future<void> main() async {
  // Aseguramos que los bindings de Flutter están listos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // (Hemos quitado 'NotificationService.init()')

  // Inicializamos los formatos de fecha en catalán
  await initializeDateFormatting('ca', null);

  // Ejecutamos la app
  runApp(const AbencerrajesApp());
}
