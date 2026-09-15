import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/google_oidc_webview.dart';
import '../../../../core/auth/session_store.dart';
import '../../domain/auth_repository.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/login_view_model.dart';
import '../widgets/auth_scaffold.dart';

/// Email/password sign-in, plus a "Continue with Google" option that hosts
/// the OIDC flow in an embedded web view (FR-01).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel(
        repository: context.read<AuthRepository>(),
        authViewModel: context.read<AuthViewModel>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<LoginViewModel>().submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    // On success the router's auth guard (listening to AuthViewModel)
    // redirects to Home automatically; on failure the ViewModel's
    // errorMessage is already shown below.
  }

  void _continueWithGoogle() {
    final sessionStore = context.read<SessionStore>();
    final authViewModel = context.read<AuthViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoogleOAuthScreen(
          sessionStore: sessionStore,
          onSuccess: authViewModel.completeLogin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return AuthScaffold(
      title: 'Welcome back',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (viewModel.errorMessage != null) ...[
              Text(
                viewModel.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: viewModel.isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: viewModel.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 8),
            AuthFooter(
              dividerLabel: 'Sign in with',
              onGooglePressed: _continueWithGoogle,
              promptText: "Don't have an account?",
              actionText: 'Sign up',
              onActionPressed: () => context.go('/signup'),
            ),
          ],
        ),
      ),
    );
  }
}
