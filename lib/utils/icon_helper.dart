// lib/utils/icon_helper.dart
import 'package:flutter/material.dart';

// CAMBIO: Ahora aceptamos "String?" (con interrogante) para que no falle si es nulo
IconData getIconData(String? name, {String type = 'event'}) {
  // Si es nulo o vacío, devolvemos el icono por defecto según el tipo
  if (name == null || name.isEmpty) {
    return type == 'voting' ? Icons.how_to_vote : Icons.event;
  }

  switch (name) {
    // --- SOCIAL & FIESTA ---
    case 'party': return Icons.celebration;
    case 'birthday': return Icons.cake;
    case 'music': return Icons.music_note;
    case 'dance': return Icons.nightlife;
    case 'beer': return Icons.sports_bar;
    case 'wine': return Icons.wine_bar;

    // --- COMIDA ---
    case 'dinner': return Icons.restaurant;
    case 'lunch': return Icons.restaurant_menu;
    case 'bbq': return Icons.outdoor_grill;
    case 'coffee': return Icons.local_cafe;

    // --- DEPORTES & AIRE LIBRE ---
    case 'sports': return Icons.sports_soccer;
    case 'gym': return Icons.fitness_center;
    case 'hiking': return Icons.hiking;
    case 'beach': return Icons.beach_access;
    case 'travel': return Icons.flight_takeoff;
    
    // --- REUNIONES & SERIO ---
    case 'meeting': return Icons.groups;
    case 'work': return Icons.work;
    case 'study': return Icons.menu_book;
    case 'presentation': return Icons.co_present;

    // --- VOTACIONES ---
    case 'vote_yesno': return Icons.thumbs_up_down;
    case 'vote_check': return Icons.check_circle_outline;
    case 'vote_star': return Icons.star_border;
    case 'vote_poll': return Icons.poll;

    // --- OTROS ---
    case 'cinema': return Icons.movie;
    case 'game': return Icons.sports_esports;
    case 'photography': return Icons.camera_alt;
    case 'shopping': return Icons.shopping_bag;
    
    // --- POR DEFECTO ---
    case 'default':
    default:
      return type == 'voting' ? Icons.how_to_vote : Icons.event;
  }
}