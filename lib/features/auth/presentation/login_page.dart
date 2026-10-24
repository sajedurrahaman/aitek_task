import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/api_config.dart';
import '../../../core/widgets/app_widgets.dart';
import '../domain/credential_rules.dart';
import 'auth_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return LoginView(
          loading: state is AuthSigningIn,
          errorMessage: state is AuthSignedOut ? state.message : null,
          initialLogin: ApiConfig.demoLogin,
          initialPassword: ApiConfig.demoPassword,
          onSubmit: (login, password) {
            context.read<AuthCubit>().login(login: login, password: password);
          },
        );
      },
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.loading,
    required this.onSubmit,
    this.errorMessage,
    this.initialLogin = '',
    this.initialPassword = '',
  });

  final bool loading;
  final String? errorMessage;
  final String initialLogin;
  final String initialPassword;
  final void Function(int login, String password) onSubmit;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController(text: widget.initialLogin);
    _passwordController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.loading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final login = CredentialRules.parseLogin(_loginController.text);
    if (login == null) return;
    widget.onSubmit(login, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 460,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 28 : 20,
              vertical: 28,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Client Cabinet',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your account number and password.',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  if (widget.errorMessage != null) ...[
                    InlineNotice(message: widget.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _loginController,
                    enabled: !widget.loading,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Login',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: CredentialRules.validateLogin,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !widget.loading,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: widget.loading
                            ? null
                            : () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: CredentialRules.validatePassword,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: widget.loading ? null : _submit,
                    child: widget.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
