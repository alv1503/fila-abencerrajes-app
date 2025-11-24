// lib/pages/forms/create_order_sheet_page.dart
import 'package:abenceapp/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateOrderSheetPage extends StatefulWidget {
  const CreateOrderSheetPage({super.key});

  @override
  State<CreateOrderSheetPage> createState() => _CreateOrderSheetPageState();
}

class _CreateOrderSheetPageState extends State<CreateOrderSheetPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _deadline;
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona data límit.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirestoreService().createOrderSheet(
        _titleController.text.trim(),
        _descController.text.trim(),
        _deadline!,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nou Full d\'Encàrrecs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Títol (Ex: Polars 2025)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requerit' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripció / Preus / Instruccions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ListTile(
                title: Text(
                  _deadline == null
                      ? 'Data Límit per apuntar-se'
                      : 'Fins al: ${DateFormat('dd/MM/yyyy').format(_deadline!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _deadline = date);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Crear Full'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
