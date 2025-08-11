// lib/screens/balance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:async';

class BalanceScreen extends StatefulWidget {
  final String username;
  const BalanceScreen({super.key, required this.username});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  int? _balance;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final results = await Future.wait([
        auth.fetchBalance(widget.username),
        auth.fetchTransactions(widget.username, limit: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _balance = results[0] as int;
        _items = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _amountChip(int amount) {
    final isCredit = amount >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCredit ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCredit ? Colors.green : Colors.red, width: 1),
      ),
      child: Text(
        (isCredit ? '+ ' : '- ') + amount.abs().toString(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _balance == null ? "Balance" : "Balance: ${_balance!} eddies";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 1 + _items.length, // 1 for the balance header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Balance",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _balance?.toString() ?? "-",
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Recent Transactions",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      }

                      final tx = _items[index - 1];
                      final amount = (tx['amount'] as num?)?.toInt() ?? 0;
                      final desc = (tx['description'] as String?) ?? '';
                      final createdAt = (tx['created_at'] as String?) ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(desc.isEmpty ? 'Transaction' : desc),
                          subtitle: Text(createdAt),
                          trailing: _amountChip(amount),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
