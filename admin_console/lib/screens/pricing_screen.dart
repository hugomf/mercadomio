import 'package:flutter/material.dart';
import '../models/pricing.dart';
import '../services/admin_pricing_service.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _service = AdminPricingService();
  List<PriceSchedule> _schedules = [];
  List<PriceSet> _sets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.listPriceSchedules(),
        _service.listPriceSets(),
      ]);
      setState(() {
        _schedules = results[0] as List<PriceSchedule>;
        _sets = results[1] as List<PriceSet>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sell_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load pricing'),
            const SizedBox(height: 4),
            Text(_error!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Price Schedules'),
              Tab(text: 'Price Sets'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSchedulesTab(),
                _buildSetsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- Price Schedules tab -----

  Widget _buildSchedulesTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _createSchedule,
              icon: const Icon(Icons.add),
              label: const Text('New schedule'),
            ),
          ),
          const SizedBox(height: 12),
          if (_schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No price schedules yet. Create one to adjust '
                  'prices over time (e.g. inflation, seasonal).'),
            )
          else
            for (final s in _schedules) _buildScheduleCard(s),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(PriceSchedule s) {
    final isActive = s.active &&
        !DateTime.now().isBefore(s.effectiveFrom) &&
        (s.effectiveTo == null || !DateTime.now().isAfter(s.effectiveTo!));
    final modeText = switch (s.mode) {
      ScheduleMode.percentage => '${s.value > 0 ? '+' : ''}${s.value}%',
      ScheduleMode.absolute => s.value > 0 ? '+${s.value}' : '${s.value}',
      ScheduleMode.fixed => '= ${s.value}',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.trending_up : Icons.schedule,
          color: isActive ? Colors.green : Colors.grey,
        ),
        title: Text(s.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${s.scope.name} · $modeText · ${_fmtDate(s.effectiveFrom)}'
          '${s.effectiveTo != null ? ' → ${_fmtDate(s.effectiveTo!)}' : ''}\n'
          '${s.description}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit',
              onPressed: () => _editSchedule(s),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete',
              onPressed: () => _deleteSchedule(s),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSchedule() async {
    final result = await _scheduleDialog();
    if (result == null) return;
    try {
      await _service.createPriceSchedule(result);
      _snack('Price schedule created');
      await _load();
    } catch (e) {
      _snack('Failed to create price schedule: $e', error: true);
    }
  }

  Future<void> _editSchedule(PriceSchedule s) async {
    final result = await _scheduleDialog(initial: s);
    if (result == null) return;
    try {
      await _service.updatePriceSchedule(s.id, result.toJson());
      _snack('Price schedule updated');
      await _load();
    } catch (e) {
      _snack('Failed to update price schedule: $e', error: true);
    }
  }

  Future<void> _deleteSchedule(PriceSchedule s) async {
    final ok = await _confirm('Delete schedule "${s.name}"?');
    if (ok != true) return;
    try {
      await _service.deletePriceSchedule(s.id);
      _snack('Price schedule deleted');
      await _load();
    } catch (e) {
      _snack('Failed to delete price schedule: $e', error: true);
    }
  }

  // ----- Price Sets tab -----

  Widget _buildSetsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _createSet,
              icon: const Icon(Icons.add),
              label: const Text('New price set'),
            ),
          ),
          const SizedBox(height: 12),
          if (_sets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No price sets yet. Create one for a coupon, '
                  'loyalty tier, or special customer pricing.'),
            )
          else
            for (final s in _sets) _buildSetCard(s),
        ],
      ),
    );
  }

  Widget _buildSetCard(PriceSet s) {
    final ruleText = s.rules
        .map((r) => switch (r.kind) {
              PriceRuleKind.percentage => '${r.amount}% off',
              PriceRuleKind.absolute => '-\$${r.amount}',
              PriceRuleKind.override => '=\$${r.amount}',
            })
        .join(', ');
    final condText = [
      if (s.conditions.couponCode.isNotEmpty) 'code ${s.conditions.couponCode}',
      if (s.conditions.minSubtotal > 0)
        'min \$${s.conditions.minSubtotal}',
      if (s.conditions.minQuantity > 0)
        'min qty ${s.conditions.minQuantity}',
      if (s.conditions.customerTier.isNotEmpty)
        'tier ${s.conditions.customerTier}',
      if (s.conditions.customerIds.isNotEmpty)
        'customers ${s.conditions.customerIds.length}',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          s.active ? Icons.local_offer : Icons.local_offer_outlined,
          color: s.active ? Colors.deepPurple : Colors.grey,
        ),
        title: Text(s.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$ruleText${condText.isNotEmpty ? '\n$condText' : ''}'
          '${s.stopFurtherRules ? '\nStops further rules' : ''}'
          '${s.maxUses > 0 ? '\nUsed ${s.usedCount}/${s.maxUses}' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit',
              onPressed: () => _editSet(s),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete',
              onPressed: () => _deleteSet(s),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSet() async {
    final result = await _setDialog();
    if (result == null) return;
    try {
      await _service.createPriceSet(result);
      _snack('Price set created');
      await _load();
    } catch (e) {
      _snack('Failed to create price set: $e', error: true);
    }
  }

  Future<void> _editSet(PriceSet s) async {
    final result = await _setDialog(initial: s);
    if (result == null) return;
    try {
      await _service.updatePriceSet(s.id, result.toJson());
      _snack('Price set updated');
      await _load();
    } catch (e) {
      _snack('Failed to update price set: $e', error: true);
    }
  }

  Future<void> _deleteSet(PriceSet s) async {
    final ok = await _confirm('Delete price set "${s.name}"?');
    if (ok != true) return;
    try {
      await _service.deletePriceSet(s.id);
      _snack('Price set deleted');
      await _load();
    } catch (e) {
      _snack('Failed to delete price set: $e', error: true);
    }
  }

  // ----- Dialogs -----

  Future<bool?> _confirm(String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<PriceSchedule?> _scheduleDialog({PriceSchedule? initial}) async {
    final name = TextEditingController(text: initial?.name ?? '');
    final desc = TextEditingController(text: initial?.description ?? '');
    final value = TextEditingController(
        text: initial?.value.toString() ?? '');
    var scope = initial?.scope ?? ScheduleScope.global;
    var mode = initial?.mode ?? ScheduleMode.percentage;
    var priority = initial?.priority ?? 1;
    var active = initial?.active ?? true;
    var effectiveFrom = initial?.effectiveFrom ?? DateTime.now();
    DateTime? effectiveTo = initial?.effectiveTo;

    final result = await showDialog<_DialogReturn>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(initial == null ? 'New price schedule' : 'Edit price schedule'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                      controller: desc,
                      decoration: const InputDecoration(labelText: 'Description')),
                  DropdownButtonFormField<ScheduleScope>(
                    initialValue: scope,
                    decoration: const InputDecoration(labelText: 'Scope'),
                    items: ScheduleScope.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => scope = v!),
                  ),
                  DropdownButtonFormField<ScheduleMode>(
                    initialValue: mode,
                    decoration: const InputDecoration(labelText: 'Mode'),
                    items: ScheduleMode.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => mode = v!),
                  ),
                  TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Value (percent, amount, or fixed price)'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Active'),
                      Switch(
                        value: active,
                        onChanged: (v) => setDialogState(() => active = v),
                      ),
                      const Spacer(),
                      const Text('Priority'),
                      DropdownButton<int>(
                        value: priority,
                        items: [1, 2, 3, 4, 5]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => priority = v ?? 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Effective from'),
                    subtitle: Text(_fmtDate(effectiveFrom)),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: effectiveFrom,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => effectiveFrom = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Effective to (optional)'),
                    subtitle: Text(effectiveTo == null ? 'Open-ended'
                        : _fmtDate(effectiveTo!)),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setDialogState(
                          () => effectiveTo = null),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: effectiveTo ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => effectiveTo = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final v =
                      double.tryParse(value.text.replaceAll(',', '.')) ?? 0;
                  Navigator.pop(context, _DialogReturn(PriceSchedule(
                    id: initial?.id ?? '',
                    name: name.text.trim().isEmpty ? 'Untitled' : name.text.trim(),
                    description: desc.text.trim(),
                    scope: scope,
                    mode: mode,
                    value: v,
                    priority: priority,
                    active: active,
                    effectiveFrom: effectiveFrom,
                    effectiveTo: effectiveTo,
                  )));
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    return result?.schedule;
  }

  Future<PriceSet?> _setDialog({PriceSet? initial}) async {
    final name = TextEditingController(text: initial?.name ?? '');
    final desc = TextEditingController(text: initial?.description ?? '');
    final coupon =
        TextEditingController(text: initial?.conditions.couponCode ?? '');
    final tier =
        TextEditingController(text: initial?.conditions.customerTier ?? '');
    final minSubtotal = TextEditingController(
        text: initial?.conditions.minSubtotal.toString() ?? '');
    var kind = initial?.rules.isNotEmpty == true
        ? initial!.rules.first.kind
        : PriceRuleKind.percentage;
    final amount = TextEditingController(
        text: initial?.rules.isNotEmpty == true
            ? initial!.rules.first.amount.toString()
            : '');
    var priority = initial?.priority ?? 1;
    var active = initial?.active ?? true;
    var stopFurther = initial?.stopFurtherRules ?? false;
    var maxUses = initial?.maxUses ?? 0;
    DateTime? startsAt = initial?.startsAt;
    DateTime? endsAt = initial?.endsAt;

    final result = await showDialog<_DialogReturn>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(initial == null ? 'New price set' : 'Edit price set'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                      controller: desc,
                      decoration: const InputDecoration(labelText: 'Description')),
                  TextField(
                      controller: coupon,
                      decoration: const InputDecoration(
                          labelText: 'Coupon code (empty = auto)')),
                  TextField(
                      controller: tier,
                      decoration: const InputDecoration(
                          labelText: 'Customer tier (empty = anyone)')),
                  TextField(
                      controller: minSubtotal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Min subtotal (0 = none)')),
                  DropdownButtonFormField<PriceRuleKind>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Discount kind'),
                    items: PriceRuleKind.values
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => kind = v!),
                  ),
                  TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Amount (% or \$)')),
                  Row(
                    children: [
                      const Text('Active'),
                      Switch(
                        value: active,
                        onChanged: (v) => setDialogState(() => active = v),
                      ),
                      const Spacer(),
                      const Text('Priority'),
                      DropdownButton<int>(
                        value: priority,
                        items: [1, 2, 3, 4, 5]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => priority = v ?? 1),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Stop further rules'),
                    value: stopFurther,
                    onChanged: (v) => setDialogState(() => stopFurther = v ?? false),
                  ),
                  Row(
                    children: [
                      const Text('Max uses'),
                      DropdownButton<int>(
                        value: maxUses,
                        items: [0, 10, 50, 100, 1000]
                            .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e == 0 ? '∞' : '$e')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => maxUses = v ?? 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final amt =
                      double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
                  Navigator.pop(context, _DialogReturn.set(PriceSet(
                    id: initial?.id ?? '',
                    name: name.text.trim().isEmpty ? 'Untitled' : name.text.trim(),
                    description: desc.text.trim(),
                    priority: priority,
                    stopFurtherRules: stopFurther,
                    conditions: PriceConditions(
                      couponCode: coupon.text.trim().toUpperCase(),
                      customerTier: tier.text.trim(),
                      minSubtotal:
                          double.tryParse(minSubtotal.text) ?? 0,
                    ),
                    rules: [
                      PriceRule(
                        kind: kind,
                        amount: amt,
                        scope: RuleScope.all,
                        priority: 1,
                      ),
                    ],
                    maxUses: maxUses,
                    active: active,
                    startsAt: startsAt,
                    endsAt: endsAt,
                  )));
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    return result?.set;
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _DialogReturn {
  final PriceSchedule? schedule;
  final PriceSet? set;

  _DialogReturn(this.schedule)
      : set = null;
  _DialogReturn.set(PriceSet? s)
      : set = s,
        schedule = null;
}