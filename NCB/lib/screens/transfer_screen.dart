// lib/screens/transfer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../providers/auth_provider.dart';

class TransferScreen extends StatefulWidget {
  final String username; // current user
  const TransferScreen({super.key, required this.username});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final to = _toCtrl.text.trim();
    final amt = int.tryParse(_amountCtrl.text.trim());
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();

    if (to.isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter recipient and positive amount')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final resp = await auth.transfer(
        toUsername: to,
        amount: amt,
        description: desc,
      );

      final fromBal = resp['from']?['balance'];
      final toBal = resp['to']?['balance'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent $amt to $to • Your balance: $fromBal • $to: $toBal')),
      );

      // Optional: clear fields
      _amountCtrl.clear();
      _descCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TypeAheadField<String>(
              suggestionsCallback: (pattern) async {
                if (pattern.trim().isEmpty) return [];
                return await auth.searchUsers(pattern.trim());
              },
              itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
              onSelected: (suggestion) => _toCtrl.text = suggestion,
              builder: (context, controller, focusNode) {
                _toCtrl.value = controller.value; // keep controllers in sync
                return TextField(
                  controller: _toCtrl,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Recipient username'),
                );
              },
              hideOnEmpty: true,
              hideOnLoading: true,
              hideOnError: true,
              debounceDuration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (eddies)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const CircularProgressIndicator() : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}