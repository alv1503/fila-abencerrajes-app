// lib/models/order_sheet_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderSheetModel {
  final String id;
  final String title;
  final String description;
  final Timestamp deadline; // Data límit
  final bool isActive; // Si està oberta o tancada
  final List<OrderItem> items; // Llista de comandes

  OrderSheetModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.isActive,
    required this.items,
  });

  factory OrderSheetModel.fromJson(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    var list = data['items'] as List? ?? [];
    List<OrderItem> itemsList = list.map((i) => OrderItem.fromJson(i)).toList();

    return OrderSheetModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: data['deadline'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
      items: itemsList,
    );
  }
}

class OrderItem {
  final String uid;
  final String mote;
  final String orderText; // Ex: "Talla L, 2 unitats"
  final Timestamp timestamp;

  OrderItem({
    required this.uid,
    required this.mote,
    required this.orderText,
    required this.timestamp,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      uid: json['uid'] ?? '',
      mote: json['mote'] ?? 'Desconegut',
      orderText: json['orderText'] ?? '',
      timestamp: json['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'mote': mote,
      'orderText': orderText,
      'timestamp': timestamp,
    };
  }
}
