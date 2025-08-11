import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ShopScreen extends StatefulWidget {
  final String username;
  const ShopScreen({super.key, required this.username});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int? _buyingItemId; // disable button while purchasing
  String _query = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final items = await auth.fetchShopItems();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((it) {
      final name = (it['name'] as String? ?? '').toLowerCase();
      final desc = (it['description'] as String? ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory(List<Map<String, dynamic>> items) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final it in items) {
      final cat = (it['category'] as String?)?.trim();
      final key = (cat == null || cat.isEmpty) ? 'Uncategorized' : cat;
      map.putIfAbsent(key, () => []).add(it);
    }
    for (final list in map.values) {
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }
    final sortedKeys = map.keys.toList()..sort();
    return { for (final k in sortedKeys) k : map[k]! };
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final int id = (item['id'] as num).toInt();
    final String name = item['name'] as String;
    final int price = (item['price'] as num).toInt();
    final int? stock = item['stock'] == null ? null : (item['stock'] as num).toInt();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text('Buy "$name" for $price eddies?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Buy')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _buyingItemId = id);
    try {
      final resp = await auth.purchaseItem(itemId: id);
      final newBalance = (resp['balance'] ?? resp['from']?['balance']) ?? '—';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased $name. New balance: $newBalance')),
      );

      // Update local stock display if limited
      if (stock != null) {
        setState(() {
          final idx = _items.indexWhere((it) => (it['id'] as num).toInt() == id);
          if (idx != -1) {
            final currentStock = _items[idx]['stock'];
            if (currentStock != null) {
              final int s = (currentStock as num).toInt();
              _items[idx]['stock'] = (s > 0) ? s - 1 : 0;
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _buyingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadItems, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final filtered = _applyFilter(_items);
    final grouped = _groupByCategory(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(onPressed: _loadItems, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Search bar
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search items…',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = "");
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Collapsible categories
            for (final entry in grouped.entries) ...[
              Theme(
                // Make the expansion tile dense/compact
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false, // start collapsed
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium)),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${entry.value.length}'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entry.value.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final it = entry.value[i];
                          final name = it['name'] as String? ?? 'Item';
                          final desc = it['description'] as String? ?? '';
                          final price = (it['price'] as num?)?.toInt() ?? 0;
                          final stock = it['stock'] == null ? null : (it['stock'] as num).toInt();
                          final limited = stock != null;
                          final outOfStock = stock != null && stock <= 0;
                          final buying = _buyingItemId == (it['id'] as num).toInt();

                          return ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (desc.isNotEmpty) Text(desc),
                                Text(limited ? 'Stock: $stock' : 'Stock: Unlimited'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: (outOfStock || buying) ? null : () => _buyItem(it),
                              child: buying
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text('Buy ($price)'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
