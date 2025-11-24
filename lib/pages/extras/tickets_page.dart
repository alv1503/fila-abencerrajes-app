// lib/pages/extras/tickets_page.dart
import 'package:abenceapp/models/ticket_model.dart';
import 'package:abenceapp/models/user_model.dart';
import 'package:abenceapp/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
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

  void _showAddDialog() {
    final conceptController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Afegir Pagament"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: conceptController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "Concepte (Ex: Gel)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Import (€)",
                border: OutlineInputBorder(),
                suffixText: "€",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel·lar"),
          ),
          ElevatedButton(
            onPressed: () {
              final double? amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );
              if (conceptController.text.isNotEmpty && amount != null) {
                _firestoreService.addTicket(
                  conceptController.text.trim(),
                  amount,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Afegir"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTicket(TicketModel ticket) async {
    // Només pots esborrar si és teu o si eres admin
    if (ticket.payerUid != _currentUserId && !_isAdmin) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Esborrar"),
        content: const Text("Eliminar aquest pagament?"),
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
    if (confirm == true) await _firestoreService.deleteTicket(ticket.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes i Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Afegir Pagament",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final tickets = docs.map((d) => TicketModel.fromJson(d)).toList();

          // Calcular Total
          double totalSpent = 0;
          for (var t in tickets) {
            totalSpent += t.amount;
          }

          return Column(
            children: [
              // --- CAPÇALERA TOTAL ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.green[50],
                child: Column(
                  children: [
                    const Text(
                      "DESPESA TOTAL ACUMULADA",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "${totalSpent.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- LLISTA ---
              Expanded(
                child: tickets.isEmpty
                    ? const Center(
                        child: Text("No hi ha pagaments registrats."),
                      )
                    : ListView.builder(
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          final bool isMine = ticket.payerUid == _currentUserId;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              ticket.concept,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Pagat per: ${ticket.payerMote} • ${DateFormat('dd/MM').format(ticket.date.toDate())}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${ticket.amount.toStringAsFixed(2)} €",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isMine || _isAdmin)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteTicket(ticket),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
