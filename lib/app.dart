import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/network/connectivity_cubit.dart';
import 'core/network/network_status.dart';
import 'core/storage/secure_key_value_store.dart';
import 'core/storage/session_store.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_widgets.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/home/home_shell.dart';
import 'features/profile/data/profile_api.dart';
import 'features/profile/data/profile_repository_impl.dart';
import 'features/profile/domain/profile_repository.dart';
import 'features/promo/data/promo_api.dart';
import 'features/promo/data/promo_repository_impl.dart';
import 'features/promo/domain/promo_repository.dart';
import 'features/signals/data/signals_api.dart';
import 'features/signals/data/signals_repository_impl.dart';
import 'features/signals/domain/signals_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.authRepository,
    required this.profileRepository,
    required this.signalsRepository,
    required this.promoRepository,
    required this.sessionStore,
    required this.connectivity,
  });

  factory AppDependencies.create() {
    final client = ApiClient();
    final connectivity = Connectivity();
    final network = ConnectivityNetworkStatus(connectivity);
    return AppDependencies(
      authRepository: AuthRepositoryImpl(
        api: AuthApi(client),
        network: network,
      ),
      profileRepository: ProfileRepositoryImpl(
        api: ProfileApi(client),
        network: network,
      ),
      signalsRepository: SignalsRepositoryImpl(
        api: SignalsApi(client),
        network: network,
      ),
      promoRepository: PromoRepositoryImpl(
        api: PromoApi(client),
        network: network,
      ),
      sessionStore: SessionStore(SecureKeyValueStore()),
      connectivity: connectivity,
    );
  }

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final SignalsRepository signalsRepository;
  final PromoRepository promoRepository;
  final SessionStore sessionStore;
  final Connectivity connectivity;
}

class AitekApp extends StatefulWidget {
  const AitekApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<AitekApp> createState() => _AitekAppState();
}

class _AitekAppState extends State<AitekApp> {
  late final AuthCubit _authCubit;
  late final ConnectivityCubit _connectivityCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(
      repository: widget.dependencies.authRepository,
      store: widget.dependencies.sessionStore,
    );
    _connectivityCubit = ConnectivityCubit(widget.dependencies.connectivity);
  }

  @override
  void dispose() {
    _authCubit.close();
    _connectivityCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: widget.dependencies.authRepository,
        ),
        RepositoryProvider<ProfileRepository>.value(
          value: widget.dependencies.profileRepository,
        ),
        RepositoryProvider<SignalsRepository>.value(
          value: widget.dependencies.signalsRepository,
        ),
        RepositoryProvider<PromoRepository>.value(
          value: widget.dependencies.promoRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider.value(value: _connectivityCubit),
        ],
        child: MaterialApp(
          title: 'Client Cabinet',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          builder: (context, child) => _OfflineFrame(child: child),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ConnectivityCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthChecking() => const _Splash(),
          AuthSigningIn() || AuthSignedOut() => const LoginPage(),
          AuthSignedIn() => const HomeShell(key: ValueKey('cabinet')),
        };
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingBlock(label: 'Opening cabinet'));
  }
}

class _OfflineFrame extends StatelessWidget {
  const _OfflineFrame({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityCubit>().state;
    final page = child ?? const SizedBox.shrink();
    if (online) return page;
    return Column(
      children: [
        const Material(
          color: Color(0xFF8A4B08),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are offline. Requests will fail until the connection returns.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: page,
          ),
        ),
      ],
    );
  }
}
