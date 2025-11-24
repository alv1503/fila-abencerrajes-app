// lib/services/excel_service.dart
import 'dart:io';
import 'package:abenceapp/models/event_model.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:abenceapp/models/order_sheet_model.dart';

class ExcelService {
  // --- EXPORTAR CENSO COMPLET (Tots els membres) ---
  Future<void> exportMemberCensus(
    List<QueryDocumentSnapshot> membersDocs,
  ) async {
    // 1. Crear l'Excel
    var excel = Excel.createExcel();

    // Renombrar la fulla per defecte
    Sheet sheet = excel['Sheet1'];
    excel.rename('Sheet1', 'Cens Membres');
    sheet = excel['Cens Membres'];

    // 2. Crear Encapçalaments (Negreta)
    List<String> headers = [
      'Mote',
      'Nom',
      'Cognoms',
      'DNI',
      'Telèfon',
      'Email',
      'Rol',
      'Data Naixement',
    ];
    // Estil de capçalera (opcional, la llibreria excel a vegades canvia la API d'estils, ho fem simple)
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // 3. Omplir Dades
    for (var doc in membersDocs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Calculem el rol basant-nos en la lògica (o si ho tens guardat)
      String role = "Membre";
      if (data['isSenior'] == true) role = "Senior";
      // ... pots afegir més lògica si vols

      String birthDate = '';
      if (data['dataNaixement'] != null) {
        birthDate = DateFormat(
          'dd/MM/yyyy',
        ).format((data['dataNaixement'] as Timestamp).toDate());
      }

      List<CellValue> row = [
        TextCellValue(data['mote'] ?? ''),
        TextCellValue(data['nom'] ?? ''),
        TextCellValue(data['cognoms'] ?? ''),
        TextCellValue(data['dni'] ?? ''),
        TextCellValue(data['telefon'] ?? ''),
        TextCellValue(data['email'] ?? ''),
        TextCellValue(role),
        TextCellValue(birthDate),
      ];

      sheet.appendRow(row);
    }

    // 4. Guardar i Compartir
    await _saveAndShareFile(
      excel,
      "Cens_Filà_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx",
    );
  }

  // --- EXPORTAR ASSISTENTS D'UN EVENT ---
  Future<void> exportEventAttendees(EventModel event) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    excel.rename('Sheet1', 'Assistents');
    sheet = excel['Assistents'];

    // Encapçalaments
    sheet.appendRow([
      TextCellValue('Mote / Nom'),
      TextCellValue('Tipus'), // Membre o Convidat
      TextCellValue('Opció Menú'),
      TextCellValue('Convidat Per'),
    ]);

    // 1. Afegir Membres
    for (var attendee in event.attendees) {
      sheet.appendRow([
        TextCellValue(attendee['mote'] ?? 'Desconegut'),
        TextCellValue('Membre'),
        TextCellValue(attendee['selection'] ?? 'Sense Opció'),
        TextCellValue('-'), // No és convidat per ningú
      ]);
    }

    // 2. Afegir Convidats Manuals
    for (var guest in event.manualGuests) {
      sheet.appendRow([
        TextCellValue(guest['name'] ?? 'Convidat'),
        TextCellValue('Convidat Extern'),
        TextCellValue(guest['selection'] ?? 'Sense Opció'),
        TextCellValue(guest['addedByMote'] ?? 'Admin'),
      ]);
    }

    String safeTitle = event.title.replaceAll(
      RegExp(r'[^\w\s]+'),
      '',
    ); // Llevar caràcters rars
    await _saveAndShareFile(
      excel,
      "Llista_${safeTitle}_${DateFormat('yyyyMMdd').format(event.date.toDate())}.xlsx",
    );
  }

  // --- FUNCIÓ INTERNA PER A GUARDAR I OBRIR ---
  Future<void> _saveAndShareFile(Excel excel, String fileName) async {
    // Codificar l'excel a bytes
    var fileBytes = excel.save();
    if (fileBytes == null) return;

    // Buscar directori temporal
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/$fileName";

    // Crear el fitxer real
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    // Obrir el menú de compartir
    // XFiles és el format nou de share_plus
    await Share.shareXFiles([
      XFile(path),
    ], text: 'Aquí tens l\'arxiu Excel exportat.');
  }

  // --- EXPORTAR FULL DE COMANDA (ENCÀRRECS) ---
  Future<void> exportOrderSheet(OrderSheetModel sheet) async {
    var excel = Excel.createExcel();
    Sheet s = excel['Sheet1'];
    excel.rename('Sheet1', 'Comanda');
    s = excel['Comanda'];

    // Títol i Descripció
    s.appendRow([TextCellValue(sheet.title)]);
    s.appendRow([TextCellValue(sheet.description)]);
    s.appendRow([
      TextCellValue(
        "Data límit: ${DateFormat('dd/MM/yyyy').format(sheet.deadline.toDate())}",
      ),
    ]);
    s.appendRow([TextCellValue("")]); // Espai buit

    // Encapçalaments
    s.appendRow([
      TextCellValue('Soci (Mote)'),
      TextCellValue('Detall de la Comanda'),
      TextCellValue('Data Apuntat'),
    ]);

    // Dades
    for (var item in sheet.items) {
      s.appendRow([
        TextCellValue(item.mote),
        TextCellValue(item.orderText),
        TextCellValue(
          DateFormat('dd/MM HH:mm').format(item.timestamp.toDate()),
        ),
      ]);
    }

    String safeTitle = sheet.title.replaceAll(RegExp(r'[^\w\s]+'), '');
    await _saveAndShareFile(excel, "Comanda_$safeTitle.xlsx");
  }
}
