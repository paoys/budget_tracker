// lib/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  CategoryType?  _filterCategory;
  PaymentMode?   _filterPayment;
  DateTimeRange? _filterDateRange;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _filterCategory != null ||
      _filterPayment != null ||
      _filterDateRange != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() => setState(() {
        _filterCategory  = null;
        _filterPayment   = null;
        _filterDateRange = null;
        _searchQuery     = '';
        _searchCtrl.clear();
      });

  List<Expense> _applyFilters(List<Expense> all) {
    var list = all.toList()..sort((a, b) => b.date.compareTo(a.date));
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) =>
          e.title.toLowerCase().contains(q) ||
          (e.notes?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_filterCategory != null) {
      list = list.where((e) => e.category == _filterCategory).toList();
    }
    if (_filterPayment != null) {
      list = list.where((e) => e.paymentMode == _filterPayment).toList();
    }
    if (_filterDateRange != null) {
      final start = _filterDateRange!.start;
      final end   = _filterDateRange!.end.add(const Duration(days: 1));
      list = list.where((e) =>
          e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(end)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p      = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final filtered = _applyFilters(p.expenses);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_expenses_fab',
        onPressed: () => _showAddExpense(context),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.bg,
        icon: const Icon(Icons.add, size: 18),
        label: Text('Log Expense', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        elevation: 0,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
            child: Column(children: [
        // ── Stats ────────────────────────────────────────────────────────────
        Container(
          color: colors.bg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(child: StatTile(label: 'Spent', value: p.totalSpent, icon: Icons.trending_up_rounded)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(label: 'Remaining', value: p.remainingTotal,
                accentColor: p.remainingTotal < 0 ? kDangerColor : kSuccessColor,
                icon: Icons.account_balance_wallet_outlined)),
          ]),
        ),

        // ── Search bar ───────────────────────────────────────────────────────
        Container(
          color: colors.bg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search expenses…',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
                    prefixIcon: Icon(Icons.search, size: 18, color: colors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () => setState(() { _searchQuery = ''; _searchCtrl.clear(); }),
                            child: Icon(Icons.close, size: 16, color: colors.textMuted))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Filter icon button
            GestureDetector(
              onTap: () => _showFilterSheet(context, colors),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (_filterPayment != null || _filterDateRange != null)
                      ? colors.textPrimary
                      : colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_filterPayment != null || _filterDateRange != null)
                        ? colors.textPrimary
                        : colors.divider,
                  ),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Icon(Icons.tune_rounded, size: 18,
                      color: (_filterPayment != null || _filterDateRange != null)
                          ? colors.bg
                          : colors.textSecondary),
                  if (_filterPayment != null || _filterDateRange != null)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: kDangerColor, shape: BoxShape.circle)),
                    ),
                ]),
              ),
            ),
          ]),
        ),

        // ── Category pills ───────────────────────────────────────────────────
        Container(
          color: colors.bg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _Pill('All', _filterCategory == null && !_hasActiveFilters, colors, _clearFilters),
              const SizedBox(width: 8),
              _CategoryPill(CategoryType.needs,   _filterCategory, colors,
                  () => setState(() => _filterCategory = _filterCategory == CategoryType.needs   ? null : CategoryType.needs)),
              const SizedBox(width: 8),
              _CategoryPill(CategoryType.wants,   _filterCategory, colors,
                  () => setState(() => _filterCategory = _filterCategory == CategoryType.wants   ? null : CategoryType.wants)),
              const SizedBox(width: 8),
              _CategoryPill(CategoryType.savings, _filterCategory, colors,
                  () => setState(() => _filterCategory = _filterCategory == CategoryType.savings ? null : CategoryType.savings)),
            ]),
          ),
        ),

        // ── Active filter chips ──────────────────────────────────────────────
        if (_filterPayment != null || _filterDateRange != null)
          Container(
            color: colors.bg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                if (_filterPayment != null)
                  _ActiveFilterChip(
                    label: _paymentLabel(_filterPayment!),
                    colors: colors,
                    onRemove: () => setState(() => _filterPayment = null),
                  ),
                if (_filterPayment != null && _filterDateRange != null)
                  const SizedBox(width: 6),
                if (_filterDateRange != null)
                  _ActiveFilterChip(
                    label: '${shortDateFmt.format(_filterDateRange!.start)} – ${shortDateFmt.format(_filterDateRange!.end)}',
                    colors: colors,
                    onRemove: () => setState(() => _filterDateRange = null),
                  ),
              ]),
            ),
          ),

        Divider(height: 1, color: colors.divider),

        // ── Result count ─────────────────────────────────────────────────────
        if (_hasActiveFilters)
          Container(
            color: colors.bg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
            ),
          ),

        // ── List ─────────────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: _hasActiveFilters ? Icons.filter_list_off_rounded : Icons.receipt_long_outlined,
                  title: _hasActiveFilters ? 'No matches' : 'No expenses',
                  message: _hasActiveFilters
                      ? 'Try adjusting your filters or search term.'
                      : 'Log your first expense to start tracking.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _ExpenseCard(expense: filtered[i], provider: p),
                ),
        ),
      ]),
          ),
        );
      }),
    );
  }

  // ── Filter bottom sheet ────────────────────────────────────────────────────
  void _showFilterSheet(BuildContext context, AppColors colors) {
    PaymentMode?   tempPayment   = _filterPayment;
    DateTimeRange? tempDateRange = _filterDateRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Filter Expenses', style: Theme.of(ctx).textTheme.headlineSmall),
              TextButton(
                onPressed: () => ss(() { tempPayment = null; tempDateRange = null; }),
                child: Text('Clear all', style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
              ),
            ]),
            const SizedBox(height: 20),

            // Payment mode filter
            Text('Payment Method', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: PaymentMode.values.map((m) {
                final selected = tempPayment == m;
                return GestureDetector(
                  onTap: () => ss(() => tempPayment = selected ? null : m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? colors.textPrimary : colors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? colors.textPrimary : colors.divider),
                    ),
                    child: Text(_paymentLabel(m),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? colors.bg : colors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Date range filter
            Text('Date Range', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _datePresets().map((preset) {
                final isActive = tempDateRange != null &&
                    _sameDay(tempDateRange!.start, preset.start) &&
                    _sameDay(tempDateRange!.end,   preset.end);
                return GestureDetector(
                  onTap: () => ss(() => tempDateRange = isActive ? null : preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive ? colors.textPrimary : colors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? colors.textPrimary : colors.divider),
                    ),
                    child: Text(_presetLabel(preset),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            color: isActive ? colors.bg : colors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Custom date range picker
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(now.year + 1),
                  initialDateRange: tempDateRange,
                );
                if (picked != null) ss(() => tempDateRange = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (tempDateRange != null && !_isPreset(tempDateRange!))
                        ? colors.textPrimary
                        : colors.divider,
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.date_range_outlined, size: 18, color: colors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    (tempDateRange != null && !_isPreset(tempDateRange!))
                        ? '${shortDateFmt.format(tempDateRange!.start)} – ${shortDateFmt.format(tempDateRange!.end)}'
                        : 'Custom range…',
                    style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
                  ),
                  const Spacer(),
                  if (tempDateRange != null && !_isPreset(tempDateRange!))
                    GestureDetector(
                      onTap: () => ss(() => tempDateRange = null),
                      child: Icon(Icons.close, size: 16, color: colors.textMuted),
                    )
                  else
                    Icon(Icons.chevron_right, size: 16, color: colors.textMuted),
                ]),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _filterPayment   = tempPayment;
                    _filterDateRange = tempDateRange;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<DateTimeRange> _datePresets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      DateTimeRange(start: today, end: today),
      DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today),
      DateTimeRange(start: DateTime(now.year, now.month, 1), end: today),
      DateTimeRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0),
      ),
    ];
  }

  String _presetLabel(DateTimeRange r) {
    final presets = _datePresets();
    if (_sameDay(r.start, presets[0].start) && _sameDay(r.end, presets[0].end)) return 'Today';
    if (_sameDay(r.start, presets[1].start) && _sameDay(r.end, presets[1].end)) return 'Last 7 days';
    if (_sameDay(r.start, presets[2].start) && _sameDay(r.end, presets[2].end)) return 'This month';
    if (_sameDay(r.start, presets[3].start) && _sameDay(r.end, presets[3].end)) {
      final now = DateTime.now();
      return _monthName(DateTime(now.year, now.month - 1).month);
    }
    return '${shortDateFmt.format(r.start)} – ${shortDateFmt.format(r.end)}';
  }

  bool _isPreset(DateTimeRange r) =>
      _datePresets().any((p) => _sameDay(r.start, p.start) && _sameDay(r.end, p.end));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  String _paymentLabel(PaymentMode m) {
    const labels = ['Cash','Credit Card','Debit Card','GCash','Maya','Bank Transfer','Other'];
    return labels[m.index];
  }

  // ── Add expense sheet (unchanged) ─────────────────────────────────────────
  void _showAddExpense(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final titleCtrl  = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl  = TextEditingController();
    CategoryType selectedCat     = CategoryType.needs;
    PaymentMode  selectedPayment = PaymentMode.cash;
    String?      selectedSubId;
    String?      selectedCCId;
    DateTime     selectedDate    = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final subs = p.subCategoriesByType(selectedCat);
        return SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            Text('Log Expense', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 20),
            buildAmountField(controller: amountCtrl),
            const SizedBox(height: 12),
            TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.edit_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 20),
            const SectionLabel('Category'),
            CategorySelector(value: selectedCat, onChanged: (v) => ss(() { selectedCat = v; selectedSubId = null; })),
            if (subs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionLabel('Sub-category'),
              DropdownButtonFormField<String>(
                value: selectedSubId,
                decoration: const InputDecoration(labelText: 'Select sub-category (optional)'),
                items: [const DropdownMenuItem(value: null, child: Text('None')), ...subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))],
                onChanged: (v) => ss(() => selectedSubId = v),
              ),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Payment Method'),
            DropdownButtonFormField<PaymentMode>(
              value: selectedPayment,
              decoration: const InputDecoration(labelText: 'How did you pay?'),
              items: PaymentMode.values.map((m) {
                final icons = [Icons.payments_outlined, Icons.credit_card, Icons.credit_card_outlined, Icons.phone_android, Icons.phone_android_outlined, Icons.account_balance_outlined, Icons.more_horiz];
                const labels = ['Cash', 'Credit Card', 'Debit Card', 'GCash', 'Maya', 'Bank Transfer', 'Other'];
                return DropdownMenuItem(value: m, child: Row(children: [Icon(icons[m.index], size: 16), const SizedBox(width: 8), Text(labels[m.index])]));
              }).toList(),
              onChanged: (v) => ss(() { selectedPayment = v!; if (v != PaymentMode.creditCard) selectedCCId = null; }),
            ),
            if (selectedPayment == PaymentMode.creditCard && p.creditCards.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCCId,
                decoration: const InputDecoration(labelText: 'Select Card'),
                items: p.creditCards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => ss(() => selectedCCId = v),
                validator: (v) => selectedPayment == PaymentMode.creditCard && v == null ? 'Pick a card' : null,
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) ss(() => selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Theme.of(ctx).extension<AppColors>()!.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(ctx).extension<AppColors>()!.divider)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(ctx).extension<AppColors>()!.textSecondary),
                  const SizedBox(width: 10),
                  Text(dateFmt.format(selectedDate), style: GoogleFonts.inter(fontSize: 14, color: Theme.of(ctx).extension<AppColors>()!.textPrimary)),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: Theme.of(ctx).extension<AppColors>()!.textMuted),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined, size: 18)), maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                p.addExpense(Expense(id: p.newId(), title: titleCtrl.text.trim(), amount: double.parse(amountCtrl.text.trim()), category: selectedCat, subCategoryId: selectedSubId, paymentMode: selectedPayment, date: selectedDate, notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(), creditCardId: selectedCCId));
                Navigator.pop(ctx);
              },
              child: const Text('Log Expense'),
            )),
          ])),
        );
      }),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final AppColors colors;
  final VoidCallback onRemove;
  const _ActiveFilterChip({required this.label, required this.colors, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 10, right: 6, top: 5, bottom: 5),
    decoration: BoxDecoration(
      color: colors.textPrimary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colors.textPrimary.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textPrimary)),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: onRemove,
        child: Icon(Icons.close, size: 13, color: colors.textPrimary),
      ),
    ]),
  );
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final AppProvider provider;
  const _ExpenseCard({required this.expense, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final c   = colors.forCategory(expense.category);
    final sub = expense.subCategoryId != null ? provider.subCategories.where((s) => s.id == expense.subCategoryId).firstOrNull : null;
    final cc  = expense.creditCardId  != null ? provider.creditCards.where((card) => card.id == expense.creditCardId).firstOrNull : null;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: kDangerColor.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.delete_outline_rounded, color: kDangerColor), Text('Delete', style: GoogleFonts.inter(fontSize: 11, color: kDangerColor, fontWeight: FontWeight.w600))]),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Remove "${expense.title}"?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: kDangerColor)))],
      )),
      onDismissed: (_) => provider.deleteExpense(expense.id),
      child: AppCard(child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withOpacity(colors.isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(_catIcon(expense.category), size: 20, color: c)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Wrap(spacing: 5, runSpacing: 4, children: [
            CategoryChip(category: expense.category),
            if (sub != null) _Tag(sub.name, colors),
            if (cc  != null) _Tag('💳 ${cc.name}', colors),
          ]),
          const SizedBox(height: 3),
          Row(children: [PaymentModeChip(mode: expense.paymentMode), const SizedBox(width: 8), Text('·', style: TextStyle(color: colors.textMuted)), const SizedBox(width: 8), Text(shortDateFmt.format(expense.date), style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted))]),
          if (expense.notes != null && expense.notes!.isNotEmpty)
            Text(expense.notes!, style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 10),
        Text(pesoFmt.format(expense.amount), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
      ])),
    );
  }

  IconData _catIcon(CategoryType t) =>
      t == CategoryType.needs ? Icons.home_outlined :
      t == CategoryType.wants ? Icons.shopping_bag_outlined :
      Icons.savings_outlined;
}

class _Tag extends StatelessWidget {
  final String label; final AppColors colors;
  const _Tag(this.label, this.colors);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: colors.textSecondary)));
}

class _Pill extends StatelessWidget {
  final String label; final bool selected; final AppColors colors; final VoidCallback onTap;
  const _Pill(this.label, this.selected, this.colors, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? colors.textPrimary : colors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? colors.textPrimary : colors.divider),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? colors.bg : colors.textSecondary))));
}

class _CategoryPill extends StatelessWidget {
  final CategoryType type; final CategoryType? selected; final AppColors colors; final VoidCallback onTap;
  const _CategoryPill(this.type, this.selected, this.colors, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isSelected = selected == type;
    final c = colors.forCategory(type);
    final label = type.name[0].toUpperCase() + type.name.substring(1);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(colors.isDark ? 0.2 : 0.12) : colors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c.withOpacity(0.6) : colors.divider),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? c : colors.textSecondary))));
  }
}