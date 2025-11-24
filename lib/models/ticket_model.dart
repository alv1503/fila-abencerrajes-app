// lib/models/ticket_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final String payerUid;
  final String payerMote; // Qui ha pagat
  final String concept;   // Què ha pagat (Ex: Gel, Carn)
  final double amount;    // Quant ha costat
  final Timestamp date;

  TicketModel({
    required this.id,
    required this.payerUid,
    required this.payerMote,
    required this.concept,
    required this.amount,
    required this.date,
  });

  factory TicketModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      id: doc.id,
      payerUid: data['payerUid'] ?? '',
      payerMote: data['payerMote'] ?? 'Anònim',
      concept: data['concept'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: data['date'] ?? Timestamp.now(),
    );
  }
}