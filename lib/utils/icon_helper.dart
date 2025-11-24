// lib/utils/icon_helper.dart
import 'package:flutter/material.dart';

/// Aquest arxiu defineix els mapes d'icones i proporciona una funció
/// d'ajuda per a obtindre la icona correcta basada en un nom.
/// Això evita haver de repetir la lògica "if/else" o "switch"
/// en múltiples pantalles.

// 1. Mapes d'Icones d'Esdeveniments
/// Associa un nom de cadena (guardat a Firestore) amb un [IconData] real.
final Map<String, IconData> eventIcons = {
  'default': Icons.calendar_today,
  'reunion': Icons.people,
  'comida': Icons.restaurant,
  'fiesta': Icons.celebration,
  'musica': Icons.music_note,
};

// 2. Mapes d'Icones de Votacions
/// Associa un nom de cadena amb un [IconData] per a les votacions.
final Map<String, IconData> votingIcons = {
  'default': Icons.how_to_vote,
  'cargo': Icons.person,
  'dinero': Icons.euro,
  'general': Icons.gavel,
  'idea': Icons.lightbulb,
};

// 3. Funció d'ajuda principal
/// Retorna el [IconData] correcte basat en el [iconName] (String)
/// rebut des de Firestore.
///
/// [type] (tipus) s'utilitza per a saber en quin mapa buscar ('event' o 'voting').
IconData getIconData(String? iconName, {String type = 'event'}) {
  if (type == 'event') {
    // Busca l'iconName al mapa d'esdeveniments.
    // Si no el troba (o si iconName és nul), retorna la icona 'default'.
    return eventIcons[iconName] ?? eventIcons['default']!;
  } else {
    // Busca l'iconName al mapa de votacions.
    return votingIcons[iconName] ?? votingIcons['default']!;
  }
}
