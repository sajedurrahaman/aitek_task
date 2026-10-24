import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/config/api_config.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/trading_signal.dart';
import 'signals_cubit.dart';

class SignalsPage extends StatelessWidget {
  const SignalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignalsCubit, SignalsState>(
      builder: (context, state) {
        final cubit = context.read<SignalsCubit>();
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: ResponsiveCenter(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'Trading system ${ApiConfig.tradingSystem}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final pair in ApiConfig.currencyPairs)
                            FilterChip(
                              label: Text(pair),
                              selected: state.selectedPairs.contains(pair),
                              onSelected: state.status == SignalsStatus.loading
                                  ? null
                                  : (_) => cubit.togglePair(pair),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: state.status == SignalsStatus.loading
                                ? null
                                : cubit.selectAll,
                            child: const Text('Select all'),
                          ),
                          TextButton(
                            onPressed: state.status == SignalsStatus.loading
                                ? null
                                : cubit.clearPairs,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: state.status == SignalsStatus.loading
                            ? null
                            : () => _pickRange(context, state),
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(_rangeLabel(state.from, state.to)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: state.status == SignalsStatus.loading
                            ? null
                            : cubit.load,
                        icon: state.status == SignalsStatus.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_outlined),
                        label: Text(
                          state.status == SignalsStatus.loading
                              ? 'Loading'
                              : 'Load signals',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                ..._resultSlivers(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickRange(BuildContext context, SignalsState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2016),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: state.from, end: state.to),
      helpText: 'Signal dates',
    );
    if (picked == null || !context.mounted) return;
    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    final end = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
      23,
      59,
      59,
    );
    context.read<SignalsCubit>().setRange(start, end);
  }
}

List<Widget> _resultSlivers(BuildContext context, SignalsState state) {
  const padding = EdgeInsets.fromLTRB(16, 0, 16, 28);
  Widget box(Widget child) {
    return SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(child: child),
    );
  }

  return switch (state.status) {
    SignalsStatus.idle => [
      box(
        const EmptyState(
          icon: Icons.query_stats_outlined,
          title: 'Choose what to load',
          message:
              'Select currency pairs and a date range, then load the archive.',
        ),
      ),
    ],
    SignalsStatus.loading when state.signals.isEmpty => [
      box(
        const SizedBox(
          height: 220,
          child: LoadingBlock(label: 'Loading signals'),
        ),
      ),
    ],
    SignalsStatus.empty => [
      box(
        const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No signals',
          message: 'Nothing was found for these pairs and dates.',
        ),
      ),
    ],
    SignalsStatus.failure => [
      box(
        EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load signals',
          message: state.error ?? 'Please try again.',
          action: FilledButton(
            onPressed: () => context.read<SignalsCubit>().load(),
            child: const Text('Try again'),
          ),
        ),
      ),
    ],
    _ => [
      SliverPadding(
        padding: padding,
        sliver: SliverList.builder(
          itemCount: state.signals.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
              child: _SignalCard(signal: state.signals[index]),
            );
          },
        ),
      ),
    ],
  };
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.signal});

  final TradingSignal signal;

  @override
  Widget build(BuildContext context) {
    final buy = signal.direction == 'Buy';
    final sell = signal.direction == 'Sell';
    final tone = buy
        ? const Color(0xFF0E7C66)
        : sell
        ? const Color(0xFFB42318)
        : Theme.of(context).colorScheme.primary;
    final when = signal.openedAt == null
        ? null
        : DateFormat('d MMM yyyy, HH:mm').format(signal.openedAt!);
    final meta = [
      ?signal.period,
      ?when,
      if (signal.id != null) '#${signal.id}',
    ].join(' · ');
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  signal.pair,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  signal.direction,
                  style: TextStyle(color: tone, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          DetailRow(label: 'Entry', value: formatPrice(signal.price)),
          DetailRow(
            label: 'Take profit',
            value: formatPrice(signal.takeProfit),
          ),
          DetailRow(label: 'Stop loss', value: formatPrice(signal.stopLoss)),
          if (signal.comment != null)
            DetailRow(label: 'Comment', value: signal.comment!),
        ],
      ),
    );
  }
}

String formatPrice(double? value) {
  if (value == null) return '—';
  var text = value.toStringAsFixed(5);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text;
}

String _rangeLabel(DateTime from, DateTime to) {
  final format = DateFormat('d MMM yyyy');
  return '${format.format(from)} – ${format.format(to)}';
}
