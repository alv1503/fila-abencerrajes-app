// lib/pages/extras/order_sheets_page.dart
import 'package:abenceapp/models/order_sheet_model.dart';
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/pages/forms/create_order_sheet_page.dart';
import 'package:abenceapp/services/excel_service.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- PÀGINA 1: LLISTAT DE FULLS ---
class OrderSheetsListPage extends StatelessWidget {
  const OrderSheetsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Fulls d\'Encàrrecs')),
      // Botó flotant només per a Admin (ho comprovem dins del FutureBuilder o ho deixem obert si vols que tots creïn)
      // Per seguretat, fem un FutureBuilder ràpid per saber si és admin
      floatingActionButton: FutureBuilder<MemberModel>(
        future: firestoreService.getMemberDetails(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isAdmin) {
            return FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateOrderSheetPage(),
                ),
              ),
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getOrderSheetsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No hi ha fulls d'encàrrecs actius.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final sheets = snapshot.data!.docs
              .map((doc) => OrderSheetModel.fromJson(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sheets.length,
            itemBuilder: (context, index) {
              final sheet = sheets[index];
              final bool isExpired = sheet.deadline.toDate().isBefore(
                DateTime.now(),
              );

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: sheet.isActive && !isExpired
                        ? Colors.teal
                        : Colors.grey,
                    child: const Icon(Icons.shopping_bag, color: Colors.white),
                  ),
                  title: Text(
                    sheet.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sheet.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Límit: ${DateFormat('dd/MM/yyyy').format(sheet.deadline.toDate())}",
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderSheetDetailPage(sheet: sheet),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- PÀGINA 2: DETALL I APUNTAR-SE ---
class OrderSheetDetailPage extends StatefulWidget {
  final OrderSheetModel sheet;
  const OrderSheetDetailPage({super.key, required this.sheet});

  @override
  State<OrderSheetDetailPage> createState() => _OrderSheetDetailPageState();
}

class _OrderSheetDetailPageState extends State<OrderSheetDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _orderController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final user = await _firestoreService.getMemberDetails(_currentUserId);
      if (mounted) setState(() => _isAdmin = user.isAdmin);
    } catch (e) {
      /*...*/
    }
  }

  Future<void> _addItem() async {
    if (_orderController.text.trim().isEmpty) return;
    try {
      await _firestoreService.addOrderItem(
        widget.sheet.id,
        _orderController.text.trim(),
      );
      _orderController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Afegit!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteItem(OrderItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Esborrar"),
        content: const Text("Segur que vols llevar això?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Sí"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.removeOrderItem(widget.sheet.id, item.toJson());
    }
  }

  Future<void> _deleteSheet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("ESBORRAR FULL"),
        content: const Text("Això esborrarà tota la llista per sempre."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Esborrar"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteOrderSheet(widget.sheet.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.orderSheets.doc(widget.sheet.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("El full ha sigut esborrat.")),
          );
        }

        final OrderSheetModel liveSheet = OrderSheetModel.fromJson(
          snapshot.data!,
        );
        final bool isExpired = liveSheet.deadline.toDate().isBefore(
          DateTime.now(),
        );
        final bool canEdit = liveSheet.isActive && !isExpired;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detall Comanda'),
            actions: [
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.table_view, color: Colors.greenAccent),
                  onPressed: () => ExcelService().exportOrderSheet(liveSheet),
                ),
              if (_isAdmin)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'toggle') {
                      _firestoreService.toggleOrderSheetStatus(
                        liveSheet.id,
                        !liveSheet.isActive,
                      );
                    }
                    if (v == 'delete') _deleteSheet();
                  },
                  itemBuilder: (c) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        liveSheet.isActive ? "Tancar Llista" : "Reobrir Llista",
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        "Esborrar Full",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // HEADER INFO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveSheet.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      liveSheet.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isExpired ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Límit: ${DateFormat('dd/MM/yyyy').format(liveSheet.deadline.toDate())}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (!liveSheet.isActive)
                          const Chip(
                            label: Text("TANCAT"),
                            backgroundColor: Colors.grey,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // LLISTA D'ITEMS (Part del fitxer order_sheets_page.dart)
              Expanded(
                child: liveSheet.items.isEmpty
                    ? const Center(child: Text("Encara no hi ha encàrrecs."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: liveSheet.items.length,
                        itemBuilder: (context, index) {
                          final item = liveSheet.items[index];
                          final bool isMine = item.uid == _currentUserId;

                          return Card(
                            // Usem Card per a separar millor
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isMine
                                ? Colors.blue[50]
                                : Colors.white, // Ressalta els meus
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isMine
                                    ? Colors.blue
                                    : Colors.grey,
                                child: Text(
                                  item.mote.isNotEmpty ? item.mote[0] : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                item.mote,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),

                              // CANVI 3: Fem el text de la comanda MOLT VISIBLE
                              subtitle: Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  item.orderText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              trailing: (isMine && canEdit) || _isAdmin
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteItem(item),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),

              // INPUT DE TEXT (Només si està actiu)
              if (canEdit)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _orderController,
                          decoration: const InputDecoration(
                            hintText: "Què necessites? (Ex: Talla L)",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addItem,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  width: double.infinity,
                  child: const Text(
                    "Llista tancada o finalitzada.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
