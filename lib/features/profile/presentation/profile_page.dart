import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/account_profile.dart';
import 'profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final login = context.read<AuthCubit>().currentSession?.login;
        return RefreshIndicator(
          onRefresh: () => context.read<ProfileCubit>().load(),
          child: ResponsiveCenter(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _ProfileBody(state: state, login: login),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.state, required this.login});

  final ProfileState state;
  final int? login;

  @override
  Widget build(BuildContext context) {
    if (state.status == ProfileStatus.loading) {
      return const SizedBox(
        height: 360,
        child: LoadingBlock(label: 'Loading profile'),
      );
    }
    if (state.status == ProfileStatus.failure) {
      return SizedBox(
        height: 360,
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Profile unavailable',
          message: state.error ?? 'Please try again.',
          action: FilledButton(
            onPressed: () => context.read<ProfileCubit>().load(),
            child: const Text('Try again'),
          ),
        ),
      );
    }

    final profile = state.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.name?.isNotEmpty == true ? profile!.name! : 'Account',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                login == null ? 'Signed in' : 'Login $login',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (state.accountError != null) ...[
          const SizedBox(height: 12),
          InlineNotice(
            message: state.accountError!,
            actionLabel: 'Retry',
            onAction: () => context.read<ProfileCubit>().load(),
          ),
        ],
        if (profile != null) ...[
          const SizedBox(height: 12),
          _MoneyGrid(profile: profile),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: [
                DetailRow(label: 'Country', value: _text(profile.country)),
                DetailRow(label: 'City', value: _text(profile.city)),
                DetailRow(label: 'Address', value: _text(profile.address)),
                DetailRow(label: 'Postal code', value: _text(profile.zipCode)),
                DetailRow(
                  label: 'Currency',
                  value: profile.currencyLabel.isEmpty
                      ? '—'
                      : profile.currencyLabel,
                ),
                DetailRow(
                  label: 'Account type',
                  value: profile.type == null ? '—' : '${profile.type}',
                ),
                DetailRow(
                  label: 'Verification',
                  value: profile.verificationLevel == null
                      ? '—'
                      : 'Level ${profile.verificationLevel}',
                ),
                DetailRow(
                  label: 'Swap free',
                  value: _yesNo(profile.isSwapFree),
                ),
                DetailRow(
                  label: 'Open trades',
                  value: _yesNo(profile.isAnyOpenTrades),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        SectionCard(
          child: state.phoneError != null && state.phone == null
              ? InlineNotice(message: state.phoneError!)
              : DetailRow(label: 'Phone', value: state.phone ?? '—'),
        ),
      ],
    );
  }
}

class _MoneyGrid extends StatelessWidget {
  const _MoneyGrid({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final currency = profile.currencyLabel;
    final items = [
      ('Balance', _money(profile.balance, currency)),
      ('Equity', _money(profile.equity, currency)),
      ('Free margin', _money(profile.freeMargin, currency)),
      ('Leverage', profile.leverage == null ? '—' : '1:${profile.leverage}'),
      ('Open trades', '${profile.currentTradesCount ?? 0}'),
      ('Open volume', _volume(profile.currentTradesVolume)),
      ('Total trades', '${profile.totalTradesCount ?? 0}'),
      ('Total volume', _volume(profile.totalTradesVolume)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 88,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return SectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _text(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  return value;
}

String _yesNo(bool? value) {
  if (value == null) return '—';
  return value ? 'Yes' : 'No';
}

String _money(double? value, String currency) {
  if (value == null) return '—';
  final amount = NumberFormat('#,##0.00').format(value);
  return currency.isEmpty ? amount : '$amount $currency';
}

String _volume(double? value) {
  if (value == null) return '—';
  return NumberFormat('#,##0.##').format(value);
}
