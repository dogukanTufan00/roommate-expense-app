import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:roommate_expense_app/api/api.dart';
import 'package:roommate_expense_app/l10n/app_localizations.dart';
import 'package:roommate_expense_app/models.dart';
import 'package:roommate_expense_app/session.dart';
import 'package:roommate_expense_app/theme.dart';
import 'package:roommate_expense_app/utils/avatar.dart';
import 'package:roommate_expense_app/utils/category.dart';
import 'package:roommate_expense_app/utils/errors.dart';
import 'package:roommate_expense_app/utils/format.dart';
import 'package:roommate_expense_app/utils/statement_pdf.dart';
import 'package:roommate_expense_app/widgets/illustration.dart';

// The "Döküm" (statement) tab: totals, who paid what, categories, the last 6 months,
// and a PDF to share. It is shown inside the home screen's TabBarView, so it returns a body.
class StatementTab extends StatefulWidget {
  const StatementTab({super.key, required this.householdId});

  final int householdId;

  @override
  State<StatementTab> createState() => _StatementTabState();
}

class _StatementTabState extends State<StatementTab> {
  // The period on screen. Both days are inclusive. It starts as the current month.
  DateTimeRange _period = _monthPeriod(DateTime.now());

  // Null until the first load succeeds.
  Statement? _statement;
  // The logged in user's id, to say "you" in the insight line. Null if not found.
  int? _myUserId;
  // Set when the first load fails, so the screen can show a retry button.
  Object? _loadError;
  // True while a request runs. The first load shows a spinner, later loads a thin bar.
  bool _loading = true;
  // True while the PDF is being built and shared.
  bool _exporting = false;
  // Counts the requests, so a slow old answer cannot replace a newer period.
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // The first and last day of one calendar month.
  static DateTimeRange _monthPeriod(DateTime month) {
    return DateTimeRange(
      start: DateTime(month.year, month.month, 1),
      end: DateTime(month.year, month.month + 1, 0),
    );
  }

  bool get _isCurrentMonth => _period == _monthPeriod(DateTime.now());

  // The next arrow is off once the month shown is the current month or later.
  bool get _canGoNext {
    final now = DateTime.now();
    return _period.start.isBefore(DateTime(now.year, now.month, 1));
  }

  // Loads the statement for _period, and my user id the first time.
  Future<void> _load() async {
    final request = ++_requestCount;
    try {
      final results = await Future.wait<Object?>([
        Api.getStatement(
          widget.householdId,
          from: _period.start,
          to: _period.end,
        ),
        _myUserId == null ? _findMyUserId() : Future.value(_myUserId),
      ]);
      if (!mounted || request != _requestCount) return;
      setState(() {
        _statement = results[0] as Statement;
        _myUserId = results[1] as int?;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted || request != _requestCount) return;
      final hadStatement = _statement != null;
      setState(() {
        _loading = false;
        if (!hadStatement) _loadError = e;
      });
      if (hadStatement) _showError(e);
    }
  }

  // Finds the logged in user in the member list, the same way the other tabs do.
  // Returns null on failure. The insight line then just uses the name.
  Future<int?> _findMyUserId() async {
    try {
      final members = await Api.getMembers(widget.householdId);
      for (final member in members) {
        if (member.email == Session.email) return member.userId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMessage(context, e))));
  }

  // Changes the period and loads it. The old numbers stay on screen until the new ones arrive.
  void _setPeriod(DateTimeRange period) {
    setState(() {
      _period = period;
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  void _shiftMonth(int delta) {
    _setPeriod(
      _monthPeriod(DateTime(_period.start.year, _period.start.month + delta)),
    );
  }

  // Lets the user pick any range. The picker must contain the range already shown.
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final firstYear = DateTime(now.year - 5);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: _period.start.isBefore(firstYear) ? _period.start : firstYear,
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _period,
    );
    if (!mounted || picked == null) return;
    _setPeriod(DateTimeRange(start: picked.start, end: picked.end));
  }

  // The file name, for example evce-dokum-2026-11.pdf for a whole month.
  String _fileName() {
    final from = _period.start;
    final to = _period.end;
    if (isWholeMonth(from, to)) {
      return 'evce-dokum-${DateFormat('yyyy-MM').format(from)}.pdf';
    }
    final day = DateFormat('yyyy-MM-dd');
    return 'evce-dokum-${day.format(from)}_${day.format(to)}.pdf';
  }

  // Builds the PDF and opens the share sheet (WhatsApp, Drive, e-mail...).
  Future<void> _sharePdf() async {
    final statement = _statement;
    if (statement == null || _exporting) return;

    final l10n = AppLocalizations.of(context);
    final tag = localeTagOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final period = formatPeriod(tag, _period.start, _period.end);
    final fileName = _fileName();

    setState(() => _exporting = true);
    try {
      final bytes = await buildStatementPdf(
        statement: statement,
        l10n: l10n,
        localeTag: tag,
        period: period,
      );
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tag = localeTagOf(context);
    final statement = _statement;

    final Widget content;
    if (statement != null) {
      content = _buildContent(statement, l10n, tag);
    } else if (_loadError != null) {
      content = _errorView(l10n);
    } else {
      content = const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _periodBar(l10n, tag),
        if (_loading && statement != null)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: content),
        if (statement != null) _shareButton(l10n),
      ],
    );
  }

  // ---- Period bar ----

  Widget _periodBar(AppLocalizations l10n, String tag) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.statementPrevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _shiftMonth(-1),
              ),
              Expanded(
                child: Text(
                  formatPeriod(tag, _period.start, _period.end),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.statementNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _canGoNext ? () => _shiftMonth(1) : null,
              ),
              IconButton(
                tooltip: l10n.statementPickRange,
                icon: const Icon(Icons.date_range_rounded),
                onPressed: _pickRange,
              ),
            ],
          ),
          // Only shown when another period is on screen, to go back to this month.
          if (!_isCurrentMonth)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ActionChip(
                label: Text(l10n.statementThisMonth),
                onPressed: () => _setPeriod(_monthPeriod(DateTime.now())),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Content ----

  Widget _buildContent(Statement s, AppLocalizations l10n, String tag) {
    final theme = Theme.of(context);
    final dominant = s.dominantPayer;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        // Lets pull to refresh work even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _summaryCard(s, l10n, tag),
          if (dominant != null) _insightCard(dominant, l10n, tag),
          if (s.expenseCount == 0)
            _emptyCard(l10n)
          else ...[
            _sectionTitle(theme, l10n.statementWhoPaid),
            for (final member in s.members) _memberRow(member, l10n, tag),
            _sectionTitle(theme, l10n.statementCategories),
            for (final category in s.categories)
              _categoryRow(category, l10n, tag),
          ],
          _sectionTitle(theme, l10n.statementLastSixMonths),
          _trendCard(s.trend, tag),
        ],
      ),
    );
  }

  Widget _errorView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage(context, _loadError!), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _setPeriod(_period),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  // The hero card: total spent in the period, and the payments next to it.
  Widget _summaryCard(Statement s, AppLocalizations l10n, String tag) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statementTotalSpent,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoneyFor(tag, s.totalExpenses),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statementExpenseCount(s.expenseCount),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.statementPaymentsTotal,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatMoneyFor(tag, s.totalPayments),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            l10n.statementPaymentCount(s.paymentCount),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // The mustard tip: who made most of the payments in this period.
  Widget _insightCard(DominantPayer payer, AppLocalizations l10n, String tag) {
    final percent = formatPercentFor(tag, payer.paidPercent);
    final text = payer.userId == _myUserId
        ? l10n.statementDominantPayerYou(percent)
        : l10n.statementDominantPayer(payer.name, percent);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mustard.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shown instead of the member and category sections when nothing was spent.
  Widget _emptyCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Illustration(
              'empty-expenses.png',
              fallbackIcon: Icons.receipt_long_rounded,
              height: 120,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.statementNoExpenses,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  // One member: what they paid, a bar against the whole, and their share and difference.
  Widget _memberRow(StatementMember m, AppLocalizations l10n, String tag) {
    final theme = Theme.of(context);
    final color = avatarColor(m.userId);
    final isMe = m.userId == _myUserId;
    final name = [
      m.name,
      if (isMe) '(${l10n.you})',
      if (!m.active) l10n.statementLeftTag,
    ].join(' ');

    final settled = m.net.abs() < 0.005;
    final netColor = settled
        ? AppColors.muted
        : m.net > 0
            ? AppColors.getsBack
            : AppColors.owes;
    final netSign = settled ? '' : (m.net > 0 ? '+' : '-');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color,
                  child: Text(
                    initials(m.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoneyFor(tag, m.paid),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '%${formatPercentFor(tag, m.paidPercent)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _bar(m.paidPercent / 100, color),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                Text(
                  l10n.statementShareLine(formatMoneyFor(tag, m.share)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  '·',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  l10n.statementNetLine(
                    '$netSign${formatMoneyFor(tag, m.net.abs())}',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: netColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // One category: icon, name, total, and a bar with its share of the period.
  Widget _categoryRow(StatementCategory c, AppLocalizations l10n, String tag) {
    final theme = Theme.of(context);
    final color = categoryColor(c.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon(c.category), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryLabel(l10n, c.category),
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        formatMoneyFor(tag, c.total),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _bar(c.percent / 100, color),
                  const SizedBox(height: 4),
                  Text(
                    '%${formatPercentFor(tag, c.percent)} · '
                    '${l10n.statementExpenseCount(c.count)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A thin rounded bar. fraction is 0 to 1.
  Widget _bar(double fraction, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.line),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0).toDouble(),
              alignment: Alignment.centerLeft,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }

  // The last six months as stacked columns, one segment per member, with a legend.
  Widget _trendCard(List<TrendMonth> trend, String tag) {
    final maxTotal = trend.fold<double>(
      0,
      (largest, m) => m.total > largest ? m.total : largest,
    );
    // Each member once, in the order they first appear, for the legend.
    final people = <int, String>{};
    for (final month in trend) {
      for (final paid in month.perMember) {
        people.putIfAbsent(paid.userId, () => paid.name);
      }
    }
    final compact = NumberFormat.compactCurrency(locale: tag, symbol: '₺');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final month in trend)
                    Expanded(
                      child: _trendColumn(month, maxTotal, compact, tag),
                    ),
                ],
              ),
            ),
            if (people.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (final entry in people.entries)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: avatarColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // One month: total on top, the stacked bar, and the month name below.
  // Bar heights are relative to the biggest month, so the months compare.
  Widget _trendColumn(
    TrendMonth month,
    double maxTotal,
    NumberFormat compact,
    String tag,
  ) {
    const barWidth = 22.0;
    const chartHeight = 110.0;
    final total = month.total;
    final barHeight = maxTotal <= 0 ? 0.0 : total / maxTotal * chartHeight;

    final Widget bar;
    if (total <= 0) {
      bar = Container(width: barWidth, height: 2, color: AppColors.line);
    } else {
      bar = SizedBox(
        width: barWidth,
        height: barHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final paid in month.perMember)
              if (paid.paid > 0)
                SizedBox(
                  width: barWidth,
                  height: paid.paid / total * barHeight,
                  child: ColoredBox(color: avatarColor(paid.userId)),
                ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            compact.format(total),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: chartHeight,
          child: Align(alignment: Alignment.bottomCenter, child: bar),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            DateFormat.MMM(tag).format(month.month),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  // The PDF button at the bottom of the tab.
  Widget _shareButton(AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _exporting ? null : _sharePdf,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(l10n.statementSharePdf),
          ),
        ),
      ),
    );
  }

  // A section title, styled like the balances tab.
  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
