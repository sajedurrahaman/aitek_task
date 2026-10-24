import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/presentation/auth_cubit.dart';
import '../profile/domain/profile_repository.dart';
import '../profile/presentation/profile_cubit.dart';
import '../profile/presentation/profile_page.dart';
import '../promo/domain/promo_repository.dart';
import '../promo/presentation/promo_cubit.dart';
import '../promo/presentation/promo_page.dart';
import '../signals/domain/signals_repository.dart';
import '../signals/presentation/signals_cubit.dart';
import '../signals/presentation/signals_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final ProfileCubit _profileCubit;
  late final SignalsCubit _signalsCubit;
  late final PromoCubit _promoCubit;

  static const _destinations = <_Destination>[
    _Destination('Profile', Icons.person_outline, Icons.person),
    _Destination(
      'Signals',
      Icons.candlestick_chart_outlined,
      Icons.candlestick_chart,
    ),
    _Destination('Promo', Icons.campaign_outlined, Icons.campaign),
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    _profileCubit = ProfileCubit(context.read<ProfileRepository>(), auth)
      ..load();
    _signalsCubit = SignalsCubit(context.read<SignalsRepository>(), auth);
    _promoCubit = PromoCubit(context.read<PromoRepository>())..load();
  }

  @override
  void dispose() {
    _profileCubit.close();
    _signalsCubit.close();
    _promoCubit.close();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will need to sign in again to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profileCubit),
        BlocProvider.value(value: _signalsCubit),
        BlocProvider.value(value: _promoCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_destinations[_index].label),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (index) =>
                    setState(() => _index = index),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in _destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selected),
                      label: Text(destination.label),
                    ),
                ],
              ),
            Expanded(
              child: switch (_index) {
                0 => const ProfilePage(),
                1 => const SignalsPage(),
                2 => const PromoPage(),
                _ => const ProfilePage(),
              },
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (index) =>
                    setState(() => _index = index),
                destinations: [
                  for (final destination in _destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selected),
                      label: destination.label,
                    ),
                ],
              ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selected);

  final String label;
  final IconData icon;
  final IconData selected;
}
