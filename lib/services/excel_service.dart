// lib/services/excel_service.dart

import 'dart:io';
import 'package:abenceapp/models/event_model.dart';
import 'package:abenceapp/models/order_sheet_model.dart'; // Asegúrate de tener este import
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelService {
  
  // --- MÉTODO AUXILIAR PARA COMPARTIR SIN ERRORES ---
  Future<void> _safeShare(String path, String text) async {
    try {
      final file = XFile(path);
      await Share.shareXFiles([file], text: text);
    } catch (e) {
      print("Aviso: El usuario canceló o hubo un error menor al compartir: $e");
    }
  }

  // --- 1. EXPORTAR ASISTENTES DE UN EVENTO ---
  Future<void> exportEventAttendees(EventModel event) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    excel.rename('Sheet1', 'Assistents');
    sheet = excel['Assistents'];

    sheet.appendRow([TextCellValue(event.title)]);
    sheet.appendRow([TextCellValue("Data: ${DateFormat('dd/MM/yyyy HH:mm').format(event.date.toDate())}")]);
    sheet.appendRow([TextCellValue("")]); 

    sheet.appendRow([
      TextCellValue("Nom / Mote"),
      TextCellValue("Tipus"),
      TextCellValue("Opció Menú"),
      TextCellValue("Convidat per"),
    ]);

    for (var attendee in event.attendees) {
      if (attendee is Map) {
        sheet.appendRow([
          TextCellValue(attendee['mote'] ?? 'Soci'),
          TextCellValue("Soci"),
          TextCellValue(attendee['selection'] ?? '-'),
          TextCellValue("-"),
        ]);
      }
    }

    for (var guest in event.manualGuests) {
      if (guest is Map) {
        sheet.appendRow([
          TextCellValue(guest['name'] ?? 'Convidat'),
          TextCellValue("Convidat"),
          TextCellValue(guest['selection'] ?? '-'),
          TextCellValue(guest['addedByMote'] ?? 'Desconegut'),
        ]);
      }
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final directory = await getTemporaryDirectory();
    final cleanTitle = event.title.replaceAll(RegExp(r'[^\w\s]+'), '');
    final path = "${directory.path}/Assistents_$cleanTitle.xlsx";

    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    await _safeShare(path, "Llista d'assistents per: ${event.title}");
  }

  // --- 2. EXPORTAR PEDIDOS (ORDER SHEETS) - LA QUE FALTABA ---
  Future<void> exportOrderSheet(OrderSheetModel sheet) async {
    var excel = Excel.createExcel();
    Sheet s = excel['Sheet1'];
    excel.rename('Sheet1', 'Comanda');
    s = excel['Comanda'];

    // Título y Descripción
    s.appendRow([TextCellValue(sheet.title)]);
    s.appendRow([TextCellValue(sheet.description)]);
    s.appendRow([
      TextCellValue(
        "Data límit: ${DateFormat('dd/MM/yyyy').format(sheet.deadline.toDate())}",
      ),
    ]);
    s.appendRow([TextCellValue("")]);

    // Encabezados
    s.appendRow([
      TextCellValue('Soci (Mote)'),
      TextCellValue('Detall de la Comanda'),
      TextCellValue('Data Apuntat'),
    ]);

    // Datos
    for (var item in sheet.items) {
      s.appendRow([
        TextCellValue(item.mote),
        TextCellValue(item.orderText),
        TextCellValue(DateFormat('dd/MM HH:mm').format(item.timestamp.toDate())),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final directory = await getTemporaryDirectory();
    final cleanTitle = sheet.title.replaceAll(RegExp(r'[^\w\s]+'), '');
    final path = "${directory.path}/Comanda_$cleanTitle.xlsx";

    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    await _safeShare(path, "Full de comanda: ${sheet.title}");
  }

  // --- 3. EXPORTAR CENSO (COMPATIBILIDAD) ---
  Future<void> exportMemberCensus(List<QueryDocumentSnapshot> membersDocs) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    excel.rename('Sheet1', 'Cens Membres');
    sheet = excel['Cens Membres'];

    List<String> headers = ['Mote', 'Nom', 'Cognoms', 'DNI', 'Telèfon', 'Email', 'Rol'];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (var doc in membersDocs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      sheet.appendRow([
        TextCellValue(data['mote'] ?? ''),
        TextCellValue(data['nom'] ?? ''),
        TextCellValue(data['cognoms'] ?? ''),
        TextCellValue(data['dni'] ?? ''),
        TextCellValue(data['telefon'] ?? ''),
        TextCellValue(data['email'] ?? ''),
        TextCellValue(data['isAdmin'] == true ? 'Admin' : 'Soci'),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/Cens_Complet.xlsx";

    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    await _safeShare(path, "Cens de socis exportat.");
  }
}